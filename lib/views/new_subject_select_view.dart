import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learningdart/enums/menu_action.dart';
import 'package:learningdart/services/auth/auth_service.dart';
import 'package:learningdart/services/cloud/firebase_cloud_storage.dart';
import 'package:learningdart/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewSubjectSelectView extends StatefulWidget {
  final String username;
  const NewSubjectSelectView({super.key, required this.username});

  @override
  State<NewSubjectSelectView> createState() => _NewSubjectSelectViewState();
}

class _NewSubjectSelectViewState extends State<NewSubjectSelectView> {
  final _manager = FirebaseCloudStorage();
  List<CategoryModel> _subjects = [];
  List<String> _userSubjects = []; // Track user's current subjects
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSubjects(),
      _loadUserSubjects(),
    ]);
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final subjectsData = await _manager.getSubjects();
      final List<CategoryModel> loadedSubjects = [];

      for (final subjectData in subjectsData) {
        final subjectName = subjectData['name'] as String;
        loadedSubjects.add(CategoryModel.fromSubject(subjectName));
      }

      setState(() {
        _subjects = loadedSubjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load subjects: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserSubjects() async {
    try {
      final user = AuthService.firebase().currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          List<dynamic> subjects = data['subjectsIntroduced'] ?? [];
          setState(() {
            _userSubjects = subjects.map((s) => s.toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user subjects: $e");
    }
  }

  Future<void> _onSubjectTap(String subject) async {
    if (_isProcessing) return;

    // Check if subject is already added
    if (_userSubjects.contains(subject)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$subject is already in your subjects!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Adding subject..."),
                ],
              ),
            ),
          );
        },
      );

      // Get current user
      final user = AuthService.firebase().currentUser;
      if (user == null) {
        throw Exception("No user logged in");
      }

      // Get current subjects and append the new one
      final updatedSubjects = [..._userSubjects, subject];

      // Update user document with the new subject appended
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
        'subjectsIntroduced': updatedSubjects,
      });

      // Update local state
      setState(() {
        _userSubjects = updatedSubjects;
      });

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$subject added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate back to UserHomeView or pop back
      if (mounted) {
        Navigator.of(context).pop(); // Use pop() instead of pushReplacement()
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to add subject: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Add a Subject",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              if (value == MenuAction.logout) {
                final shouldLogout = await showLogOutDialog(context);
                if (shouldLogout && context.mounted) {
                  await AuthService.firebase().logout();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Text("Logout"),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Select a new subject to add...",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1617),
              ),
            ),
            if (_userSubjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Current subjects: ${_userSubjects.join(', ')}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading subjects...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1617),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff92A3FD),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_subjects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No subjects available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1617),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please contact your administrator to add subjects.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      itemCount: _subjects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final isAlreadyAdded = _userSubjects.contains(subject.name);

        return GestureDetector(
          onTap: _isProcessing ? null : () => _onSubjectTap(subject.name),
          child: Opacity(
            opacity: _isProcessing ? 0.6 : (isAlreadyAdded ? 0.5 : 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isAlreadyAdded
                    // ignore: deprecated_member_use
                    ? Colors.grey.withOpacity(0.3)
                    // ignore: deprecated_member_use
                    : subject.boxColor.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: isAlreadyAdded
                        // ignore: deprecated_member_use
                        ? Colors.grey.withOpacity(0.2)
                        // ignore: deprecated_member_use
                        : subject.boxColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              // child: Column(
                child: (
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: SvgPicture.asset(
                          subject.iconPath,
                          height: 40,
                          width: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subject.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isAlreadyAdded
                              ? Colors.grey
                              : const Color(0xFF1D1617),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                  // if (isAlreadyAdded)
                  //   const Positioned(
                  //     top: 8,
                  //     right: 8,
                  //     child: Icon(
                  //       Icons.check_circle,
                  //       color: Colors.green,
                  //       size: 24,
                  //     ),
                  //   ),
                ),
              // ),
            ),
          ),
        );
      },
    );
  }
}

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text("Are you sure you want to log out?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Log Out"),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learningdart/models/category_model.dart';
import 'package:learningdart/models/stats_model.dart';
import 'package:flutter/material.dart';
import 'package:learningdart/enums/menu_action.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learningdart/services/quiz_service.dart';
import 'package:learningdart/utilities/logout_helper.dart';
import 'package:learningdart/views/new_subject_select_view.dart';
import 'package:learningdart/views/quiz_loading_view.dart';

// MAKE SURE this is the SAME instance used in main.dart
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> with RouteAware {
  List<CategoryModel> categories = [];
  List<StatsModel> stats = [];
  
  String userName = "";
  int streak = 0;
  int quizzesTaken = 0;
  int xp = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    print("🏠 UserHomeView initState called");
    _getInitialInfo();
    
    // Load data on first initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAutoRefresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("🏠 UserHomeView didChangeDependencies called");
    
    // FIXED: Proper RouteObserver subscription
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      print("🔗 Subscribed to RouteObserver");
    }
  }

  @override
  void dispose() {
    print("🏠 UserHomeView dispose called");
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // FIXED: All RouteAware methods with logging
  @override
  void didPush() {
    print("🚀 UserHomeView didPush - route was pushed and is now topmost");
    super.didPush();
  }

  @override
  void didPopNext() {
    // FIXED: This is the key method that should be called when returning from quiz
    print("🔄 UserHomeView didPopNext - returned from another screen, refreshing data");
    super.didPopNext();
    _performAutoRefresh();
  }

  @override
  void didPop() {
    print("🏠 UserHomeView didPop - this route was popped");
    super.didPop();
  }

  @override
  void didPushNext() {
    print("🏠 UserHomeView didPushNext - another route was pushed on top");
    super.didPushNext();
  }

  void _getInitialInfo() {
    // Initialize any required data
  }

  // ENHANCED: Automatic refresh method with logging
  Future<void> _performAutoRefresh() async {
    if (_isRefreshing) {
      print("⏳ Already refreshing, skipping...");
      return;
    }
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      print("🔄 Auto-refreshing user home data...");
      await Future.wait([
        _loadUserData(),
        _loadUserSubjects(),
      ]);
      print("✅ Auto-refresh completed successfully");
    } catch (e) {
      print("❌ Auto-refresh failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh data'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _performManualRefresh() async {
    print("🔄 Manual refresh triggered");
    await _performAutoRefresh();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? "User";
          streak = userDoc['streak'] ?? 0;
          quizzesTaken = userDoc['quizzesTaken'] ?? 0;
          xp = userDoc['xp'] ?? 0;

          // Build stats from Firestore values
          stats = [
            StatsModel(
              name: "$streak",
              iconPath: 'assets/icons/flames-icon.svg',
              level: '',
              duration: '',
              calorie: '',
              viewIsSelected: true,
              boxColor: const Color(0xff9DCEFF),
            ),
            StatsModel(
              name: "XP $xp",
              iconPath: 'assets/icons/lightning-thunder.svg',
              level: '',
              duration: '',
              calorie: '',
              viewIsSelected: false,
              boxColor: const Color(0xffEEA4CE),
            ),
            StatsModel(
              name: "$quizzesTaken Quizzes Taken",
              iconPath: 'assets/icons/trophy-icon.svg',
              level: '',
              duration: '',
              calorie: '',
              viewIsSelected: false,
              boxColor: const Color(0xff9DCEFF),
            ),
          ];
        });
        print("📊 User data loaded: XP=$xp, Streak=$streak, Quizzes=$quizzesTaken");
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _loadUserSubjects() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        List<dynamic> topics = userDoc['subjectsIntroduced'] ?? [];
        List<CategoryModel> loaded = topics.map((topic) {
          return CategoryModel.fromSubject(topic.toString());
        }).toList();

        setState(() {
          categories = loaded;
        });

        // OPTIMIZATION 11: Warm up cache for first few subjects
        for (int i = 0; i < min(2, categories.length); i++) {
          QuizService.warmUpCache(categories[i].name);
        }
        print("📚 Loaded ${categories.length} subjects");
      }
    } catch (e) {
      debugPrint("Error loading user subjects: $e");
    }
  }

  void _navigateToSubjectSelect() {
    print("➕ Navigating to subject selection");
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewSubjectSelectView(username: userName),
      ),
    );
    // DON'T add .then() here - RouteObserver will handle the refresh automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MasterIT',
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.black,
          size: 24,
        ),
        leading: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xffF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              'assets/icons/Arrow - Left 2.svg',
              height: 20,
              width: 20,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _performManualRefresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: _isRefreshing ? 'Refreshing...' : 'Refresh data',
          ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              if (value == MenuAction.logout) {
                await handleLogout(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: MenuAction.logout, child: Text("Logout")),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              "Welcome, $userName 👋",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _categoriesSection(),
          const SizedBox(height: 30),
          _statsSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Keep your existing _statsSection() and _categoriesSection() methods unchanged
  // But UPDATE the quiz navigation in _categoriesSection():

  Column _categoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subjects',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: _navigateToSubjectSelect,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff92A3FD).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xff92A3FD),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No subjects yet",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tap + to add subjects",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: categories.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  separatorBuilder: (context, index) => const SizedBox(width: 25),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        print("🎯 Starting quiz for ${categories[index].name}");
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuizLoadingView(
                              subjectId: categories[index].name,
                              subjectName: categories[index].name,
                            ),
                          ),
                        );
                        // DON'T add .then() here - RouteObserver will handle refresh automatically
                      },
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: categories[index].boxColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SvgPicture.asset(
                                  categories[index].iconPath,
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                categories[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Keep your existing _statsSection() method unchanged
  Column _statsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'My Stats',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 120,
          child: ListView.separated(
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                decoration: BoxDecoration(
                  color: stats[index].boxColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: SvgPicture.asset(
                          stats[index].iconPath,
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        stats[index].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemCount: stats.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ],
    );
  }
}

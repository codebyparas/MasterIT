import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learningdart/enums/menu_action.dart';
import 'package:learningdart/services/auth/auth_service.dart';
import 'initial_quiz_view.dart';

class Subject {
  final String name;
  final String iconPath;

  Subject({required this.name, required this.iconPath});
}

class SubjectSelectView extends StatelessWidget {
  final String username;
  const SubjectSelectView({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final List<Subject> subjects = [
      Subject(name: 'Java', iconPath: 'assets/icons/java.svg'),
      Subject(name: 'Geography', iconPath: 'assets/icons/planet-earth.svg'),
      Subject(name: 'Aptitude', iconPath: 'assets/icons/mind-smart-light-bulb.svg'),
      Subject(name: 'History', iconPath: 'assets/icons/java.svg'),
      Subject(name: 'Biology', iconPath: 'assets/icons/java.svg'),
      Subject(name: 'Vocabulary', iconPath: 'assets/icons/java.svg'),
    ];

    void onSubjectTap(String subject) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InitialQuizView(username: username, subject: subject),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Choose a Subject", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              if (value == MenuAction.logout) {
                final shouldLogout = await showLogOutDialog(context);
                if (shouldLogout && context.mounted) {
                  await AuthService.firebase().logout();
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
              "Select a subject to master...",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1D1617)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return GestureDetector(
                    onTap: () => onSubjectTap(subject.name),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xff92A3FD).withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(subject.iconPath, height: 60, width: 60),
                          const SizedBox(height: 12),
                          Text(
                            subject.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D1617)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learningdart/models/category_model.dart';
import 'package:learningdart/models/stats_model.dart';
// import 'package:learningdart/models/achievements_model.dart';
import 'package:flutter/material.dart';
import 'package:learningdart/enums/menu_action.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learningdart/utilities/logout_helper.dart';
import 'package:learningdart/views/new_subject_select_view.dart';

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  List<CategoryModel> categories = [];
  List<StatsModel> stats = [];
  // List<AchievementsModel> achievments = [];

  String userName = "";
  int streak = 0;
  int quizzesTaken = 0;

  @override
  void initState() {
    super.initState();
    _getInitialInfo();
    _loadUserData();
    _loadUserSubjects();
  }

  void _getInitialInfo() {
    // achievments = AchievementsModel.getPopularDiets();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? "User";
          streak = userDoc['streak'] ?? 0;
          quizzesTaken = userDoc['quizzesTaken'] ?? 0;

          // Build stats from Firestore values
          stats = [
            StatsModel(
              name: "Streak: $streak",
              iconPath: 'assets/icons/java.svg',
              level: '',
              duration: '',
              calorie: '',
              viewIsSelected: true,
              boxColor: const Color(0xff9DCEFF),
            ),
            StatsModel(
              name: "Quizzes Taken: $quizzesTaken",
              iconPath: 'assets/icons/java.svg',
              level: '',
              duration: '',
              calorie: '',
              viewIsSelected: false,
              boxColor: const Color(0xffEEA4CE),
            ),
          ];
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _loadUserSubjects() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        List<dynamic> topics = userDoc['subjectsIntroduced'] ?? [];

        List<CategoryModel> loaded = topics.map((topic) {
          return CategoryModel.fromSubject(topic.toString());
        }).toList();

        setState(() {
          categories = loaded;
        });
      }
    } catch (e) {
      debugPrint("Error loading user subjects: $e");
    }
  }

  // Navigate to subject selection
  void _navigateToSubjectSelect() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewSubjectSelectView(username: userName),
      ),
    ).then((_) {
      // Reload subjects when returning from subject selection
      _loadUserSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MasterIT',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
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
          PopupMenuButton<MenuAction>(
            icon: Container(
              margin: const EdgeInsets.all(10),
              alignment: Alignment.center,
              width: 37,
              decoration: BoxDecoration(
                color: const Color(0xffF7F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/icons/dots.svg',
                height: 5,
                width: 5,
              ),
            ),
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  await handleLogout(context);
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
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          const SizedBox(height: 40), // Removed _searchField()
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              "Welcome, $userName 👋",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _categoriesSection(),
          const SizedBox(height: 40),
          _statsSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

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
          height: 240,
          child: ListView.separated(
            itemBuilder: (context, index) {
              return Container(
                width: 210,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: stats[index].boxColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 👇 Styled same as in categories
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(stats[index].iconPath),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          stats[index].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 25),
            itemCount: stats.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ],
    );
  }

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
          height: 120,
          child: categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No subjects yet",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap + to add subjects",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: categories.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 25),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Navigate to quiz or subject details
                        // You can implement this navigation based on your app flow
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected ${categories[index].name}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: categories[index].boxColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(categories[index].iconPath),
                              ),
                            ),
                            Text(
                              categories[index].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontSize: 14,
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
}

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
import 'package:learningdart/views/quiz_loading_view.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> with RouteAware {
  List<CategoryModel> categories = [];
  List<StatsModel> stats = [];
  // List<AchievementsModel> achievments = [];

  String userName = "";
  int streak = 0;
  int quizzesTaken = 0;
  int xp = 0;

  @override
  void initState() {
    super.initState();
    _getInitialInfo();
    _loadUserData();
    _loadUserSubjects();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    if (ModalRoute.of(context) != null) {
      routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen from another screen
    print("Returned to UserHomeView - refreshing data");
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
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.black, // Sets color for all icons in AppBar
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
              onPressed: () async {
                await _loadUserData();
                await _loadUserSubjects();
              },
              icon: const Icon(Icons.refresh),
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
          // Subjects section - Now BIGGER
          _categoriesSection(),
          const SizedBox(height: 30),
          // Stats section - Now SMALLER
          _statsSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Stats section - Made SMALLER (reduced height from 240 to 120)
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
          height: 120, // Reduced from 240 to 120
          child: ListView.separated(
            itemBuilder: (context, index) {
              return Container(
                width: 120, // Reduced from 210 to 120
                decoration: BoxDecoration(
                  color: stats[index].boxColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16), // Reduced radius
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 40, // Reduced from 100 to 50
                      height: 40, // Reduced from 100 to 50
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0), // Reduced padding
                        child: SvgPicture.asset(
                          stats[index].iconPath,
                          width: 24, // Reduced from 40 to 24
                          height: 24, // Reduced from 40 to 24
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
                          fontSize: 12, // Reduced from 16 to 12
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 15), // Reduced separation
            itemCount: stats.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ],
    );
  }

  // Categories section - Made BIGGER (increased height from 120 to 200)
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
          height: 200, // Increased from 120 to 200
          child: categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48, // Increased from 32 to 48
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No subjects yet",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16, // Increased from 14 to 16
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tap + to add subjects",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14, // Increased from 12 to 14
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
                      // In your _categoriesSection() onTap method in UserHomeView
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuizLoadingView(
                              subjectId: categories[index].name,
                              subjectName: categories[index].name,
                            ),
                          ),
                        ).then((_) {
                          // This code runs when user returns from quiz
                          _loadUserData();
                          _loadUserSubjects();
                        });
                      },
                      child: Container(
                        width: 140, // Increased from 100 to 140
                        decoration: BoxDecoration(
                          color: categories[index].boxColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20), // Increased radius
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 80, // Increased from 50 to 80
                              height: 80, // Increased from 50 to 80
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0), // Increased padding
                                child: SvgPicture.asset(
                                  categories[index].iconPath,
                                  width: 40, // Increased from 24 to 40
                                  height: 40, // Increased from 24 to 40
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                categories[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600, // Increased weight
                                  color: Colors.black,
                                  fontSize: 16, // Increased from 14 to 16
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
}

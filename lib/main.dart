import 'package:flutter/material.dart';
import 'package:learningdart/constants/routes.dart';
import 'package:learningdart/views/admin_panel_view.dart';
import 'package:learningdart/views/drag_ques_test.dart';
import 'package:learningdart/views/map_ques_test.dart';
import 'package:learningdart/views/select_username_view.dart';
// import 'package:learningdart/views/upload_photo_view.dart';
import 'package:learningdart/views/user_home_view.dart';
import 'package:learningdart/services/auth/auth_service.dart';
import 'package:learningdart/views/login_view.dart';
import 'package:learningdart/views/register_view.dart';
import 'package:learningdart/views/verify_email_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.firebase().initialize();
  await Supabase.initialize(
    url: 'https://wqnxdcwwupeyiedbzfci.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxbnhkY3d3dXBleWllZGJ6ZmNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0NTMwODcsImV4cCI6MjA3MTAyOTA4N30.S-EB6ACn4c8oYNXjzynD1ckDcQ0o1udL-ZyvVf4o7pE',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.firebase().currentUser;
    late final Widget homeWidget;
    if (user != null) {
      if (user.isEmailVerified) {
        homeWidget = const LoginView();
      } else {
        homeWidget = const VerifyEmailView();
      }
    } else {
      homeWidget = const LoginView();
    }
    // homeWidget=UploadPhotoView();

    return MaterialApp(
      title: 'MasterIT',
      theme: ThemeData(useMaterial3: false, primarySwatch: Colors.blue),
      home: homeWidget,
      debugShowCheckedModeBanner: false,
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
        userHomeRoute: (context) => UserHomeView(),
        selectUsernameRoute: (context) => SelectUsernameView(),
        adminPanelRoute: (context) => AdminPanelView(),
        dragQuesRoute: (context) => DragQuesView(),
        mapQuesRoute: (context) => MapQuesView(),
      },
    );
  }
}

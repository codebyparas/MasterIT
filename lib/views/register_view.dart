import 'package:flutter/material.dart';
import 'package:learningdart/constants/routes.dart';
import 'package:learningdart/services/auth/auth_exceptions.dart';
import 'package:learningdart/services/auth/auth_service.dart';
import 'package:learningdart/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Create Account 🚀',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Join MasterIT and start learning',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7B6F72),
                  ),
                ),
                const SizedBox(height: 40),

                // Email TextField
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8F8),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password TextField
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8F8),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = _email.text;
                      final password = _password.text;
                      final navigator = Navigator.of(context);
                      try {
                        await AuthService.firebase().createUser(
                          email: email,
                          password: password,
                        );
                        AuthService.firebase().sendEmailNotification();
                        navigator.pushNamed(verifyEmailRoute);
                      } on EmailAlreadyInUseAuthException {
                        await showErrorDialog(context, "Email is already registered");
                      } on WeakPasswordAuthException {
                        await showErrorDialog(context, "Password is too weak");
                      } on GenericAuthException {
                        await showErrorDialog(context, "Failed to register");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff92A3FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Redirect
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(loginRoute, (route) => false);
                  },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      color: Color(0xffC58BF2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:learningdart/constants/routes.dart';
// import 'package:learningdart/services/auth/auth_exceptions.dart';
// import 'package:learningdart/services/auth/auth_service.dart';
// import 'package:learningdart/utilities/show_error_dialog.dart';

// class RegisterView extends StatefulWidget {
//   const RegisterView({super.key});

//   @override
//   State<RegisterView> createState() => _RegisterViewState();
// }

// class _RegisterViewState extends State<RegisterView> {
//   late final TextEditingController _email;
//   late final TextEditingController _password;

//   @override
//   void initState() {
//     _email = TextEditingController();
//     _password = TextEditingController();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _email.dispose();
//     _password.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Register")),
//       body: Column(
//         children: [
//           TextField(
//             controller: _email,
//             decoration: const InputDecoration(hintText: 'Enter the Email'),
//             keyboardType: TextInputType.emailAddress,
//           ),
//           TextField(
//             controller: _password,
//             decoration: const InputDecoration(hintText: 'Enter the Password'),
//             obscureText: true,
//             enableSuggestions: false,
//             autocorrect: false,
//           ),
//           TextButton(
//             onPressed: () async {
//               final email = _email.text;
//               final password = _password.text;
//               final navigator=Navigator.of(context);
//               try {
//                 await AuthService.firebase().createUser(email: email, password: password);
//                 AuthService.firebase().sendEmailNotification();
//                 navigator.pushNamed(verifyEmailRoute);
//               } on EmailAlreadyInUseAuthException {
//                 await showErrorDialog(context, "Email is Already Registered");
//               } on WeakPasswordAuthException {
//                 await showErrorDialog(context, "Weak Password");  
//               } on GenericAuthException {
//                 await showErrorDialog(context, "Failed to Register");
//               }
//             },
//             child: const Text('Register'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(
//                 context,
//               ).pushNamedAndRemoveUntil(loginRoute, (route) => false);
//             },
//             child: const Text("Already Registered? Login Here"),
//           ),
//         ],
//       ),
//     );
//   }
// }
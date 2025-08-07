import 'package:flutter/material.dart';
import 'package:learningdart/constants/routes.dart';
import 'package:learningdart/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: Color(0xff92A3FD),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Verify Your Email 📩",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "We’ve sent a verification link to your email address.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7B6F72),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Didn’t receive the email? You can resend it below.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B6F72),
                  ),
                ),
                const SizedBox(height: 30),

                // Resend Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthService.firebase().sendEmailNotification();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff92A3FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "Resend Verification Email",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Restart Button
                TextButton(
                  onPressed: () async {
                    await AuthService.firebase().logout();
                    await Navigator.of(context)
                        .pushNamedAndRemoveUntil(registerRoute, (route) => false);
                  },
                  child: const Text(
                    "Restart",
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
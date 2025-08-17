import 'package:flutter/material.dart';
import 'package:learningdart/constants/routes.dart';
import 'package:learningdart/services/cloud/firebase_cloud_storage.dart';
import 'package:learningdart/services/auth/auth_service.dart';

class InitialQuizView extends StatefulWidget {
  final String username;
  final String subject;

  const InitialQuizView({
    super.key,
    required this.username,
    required this.subject,
  });

  @override
  State<InitialQuizView> createState() => _InitialQuizViewState();
}

class _InitialQuizViewState extends State<InitialQuizView> {
  int _selectedOptionIndex = -1;

  final String question = "What is the capital of France?";
  final List<String> options = ["Berlin", "Madrid", "Paris", "Rome"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 0.2,
                backgroundColor: const Color(0xffF0F0F0),
                valueColor: const AlwaysStoppedAnimation(Color(0xff92A3FD)),
              ),
              const SizedBox(height: 32),
              Text(
                question,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(height: 32),
              ...List.generate(options.length, (index) {
                final isSelected = _selectedOptionIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedOptionIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xff92A3FD) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? const Color(0xff92A3FD) : const Color(0xffE5E5E5),
                      ),
                    ),
                    child: Text(
                      options[index],
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  if (_selectedOptionIndex == -1) {
                    _showSelectOptionDialog(context);
                    return;
                  }

                  final user = AuthService.firebase().currentUser;
                  if (user == null) return;

                  try {
                    await FirebaseCloudStorage().completeInitialSetup(
                      uid: user.id,
                      name: widget.username,
                      subjectsIntroduced: [widget.subject],
                    );
                    if (!mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(userHomeRoute, (_) => false);
                  } catch (_) {
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Setup Failed'),
                        content: const Text('Could not complete setup. Please try again.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xff9DCEFF), Color(0xff92A3FD)]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      'Submit',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectOptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Option Selected'),
        content: const Text('Please select an option before submitting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

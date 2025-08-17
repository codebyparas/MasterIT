import 'package:flutter/material.dart';
import 'package:learningdart/constants/routes.dart';
import 'package:learningdart/enums/menu_action.dart';
import 'package:learningdart/services/cloud/firebase_cloud_storage.dart';
import 'package:learningdart/utilities/logout_helper.dart';

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> {
  final _manager = FirebaseCloudStorage();

  final _formKey = GlobalKey<FormState>();

  String selectedEntryType = 'Subject';
  final List<String> entryTypes = ['Subject', 'Topic', 'Question'];

  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> topics = [];
  String? selectedSubjectId;
  String? selectedTopicId;

  final subjectNameController = TextEditingController();
  final topicNameController = TextEditingController();
  final questionTextController = TextEditingController();
  final optionA = TextEditingController();
  final optionB = TextEditingController();
  final optionC = TextEditingController();
  final optionD = TextEditingController();
  final correctAnswer = TextEditingController();

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final data = await _manager.getSubjects();
    setState(() {
      subjects = data;
    });
  }

  Future<void> _loadTopics(String subjectId) async {
    final data = await _manager.getTopics(subjectId);
    setState(() {
      topics = data;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);
    try {
      switch (selectedEntryType) {
        case 'Subject':
          final subjectName = subjectNameController.text.trim();
          final exists = subjects.any((s) =>
              (s['name'] as String).toLowerCase() ==
              subjectName.toLowerCase());
          if (exists) throw Exception("Subject already exists");
          await _manager.addSubject(subjectName);
          break;

        case 'Topic':
          if (selectedSubjectId == null) {
            throw Exception("Please select a subject.");
          }
          final topicName = topicNameController.text.trim();
          final duplicate = topics.any((t) =>
              (t['name'] as String).toLowerCase() ==
              topicName.toLowerCase());
          if (duplicate) throw Exception("Topic already exists.");
          final topicId = await _manager.addTopic(
            name: topicName,
            subjectId: selectedSubjectId!,
          );
          await _manager.addTopicReferenceToSubject(
            selectedSubjectId!,
            topicId,
          );
          break;

        case 'Question':
          if (selectedSubjectId == null || selectedTopicId == null) {
            throw Exception("Please select subject and topic.");
          }
          await _manager.addMCQQuestion(
            subjectId: selectedSubjectId!,
            topicId: selectedTopicId!,
            questionText: questionTextController.text.trim(),
            options: [
              optionA.text.trim(),
              optionB.text.trim(),
              optionC.text.trim(),
              optionD.text.trim(),
            ],
            correctAnswer: correctAnswer.text.trim(),
          );
          break;
      }

      _resetForm();
      await _loadSubjects();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _resetForm() {
    subjectNameController.clear();
    topicNameController.clear();
    questionTextController.clear();
    optionA.clear();
    optionB.clear();
    optionC.clear();
    optionD.clear();
    correctAnswer.clear();

    setState(() {
      selectedSubjectId = null;
      selectedTopicId = null;
      topics = [];
    });
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
        validator: (val) => val == null || val.trim().isEmpty
            ? 'Required'
            : null,
      ),
    );
  }

  Widget _buildSubjectForm() => _buildFormField(
        label: 'Subject Name',
        controller: subjectNameController,
      );

  Widget _buildTopicForm() => Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedSubjectId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Select Subject',
            ),
            items: subjects
                .map((s) => DropdownMenuItem(
                      value: s['id'] as String,
                      child: Text(s['name'] as String),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() => selectedSubjectId = val);
              if (val != null) _loadTopics(val);
            },
          ),
          const SizedBox(height: 10),
          _buildFormField(
            label: 'Topic Name',
            controller: topicNameController,
          ),
        ],
      );

  Widget _buildQuestionForm() => Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedSubjectId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Select Subject',
            ),
            items: subjects
                .map((s) => DropdownMenuItem(
                      value: s['id'] as String,
                      child: Text(s['name'] as String),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                selectedSubjectId = val;
                selectedTopicId = null;
              });
              if (val != null) _loadTopics(val);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedTopicId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Select Topic',
            ),
            items: topics
                .map((t) => DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text(t['name'] as String),
                    ))
                .toList(),
            onChanged: (val) => setState(() => selectedTopicId = val),
          ),
          const SizedBox(height: 10),
          _buildFormField(
            label: 'Question Text',
            controller: questionTextController,
          ),
          _buildFormField(label: 'Option A', controller: optionA),
          _buildFormField(label: 'Option B', controller: optionB),
          _buildFormField(label: 'Option C', controller: optionC),
          _buildFormField(label: 'Option D', controller: optionD),
          _buildFormField(
            label: 'Correct Answer (A/B/C/D)',
            controller: correctAnswer,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              if (value == MenuAction.logout) {
                await handleLogout(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: MenuAction.logout,
                child: Text("Logout"),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Add Entry',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedEntryType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Entry Type',
                    ),
                    items: entryTypes
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedEntryType = val;
                          selectedSubjectId = null;
                          selectedTopicId = null;
                          topics = [];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (selectedEntryType == 'Subject') _buildSubjectForm(),
                  if (selectedEntryType == 'Topic') _buildTopicForm(),
                  if (selectedEntryType == 'Question') _buildQuestionForm(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: isSubmitting
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text("Submit"),
                      onPressed: isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, dragQuesRoute); // <-- Replace with your actual route
                      },
                      child: const Text('Drag & Drop'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, mapQuesRoute); // <-- Replace with your actual route
                      },
                      child: const Text('Tap'),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

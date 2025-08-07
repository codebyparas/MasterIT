// admin_panel_view.dart

import 'package:flutter/material.dart';
import 'package:learningdart/services/cloud/firebase_cloud_storage.dart';

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  _AdminPanelViewState createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> {
  final _manager = FirebaseCloudStorage();
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
    try {
      if (selectedEntryType == 'Subject') {
        final subjectName = subjectNameController.text.trim();
        if (subjectName.isEmpty) throw Exception("Subject name cannot be empty");

        final exists = subjects.any((s) => (s['name'] as String).toLowerCase() == subjectName.toLowerCase());
        if (exists) throw Exception("Subject already exists");

        await _manager.addSubject(subjectName);
      }

      else if (selectedEntryType == 'Topic') {
        final topicName = topicNameController.text.trim();
        if (topicName.isEmpty) throw Exception("Topic name cannot be empty");
        if (selectedSubjectId == null) throw Exception("Select a subject");

        final currentTopics = await _manager.getTopics(selectedSubjectId!);
        final duplicate = currentTopics.any((t) => (t['name'] as String).toLowerCase() == topicName.toLowerCase());
        if (duplicate) throw Exception("Topic already exists under this subject");

        final topicId = await _manager.addTopic(
          name: topicName,
          subjectId: selectedSubjectId!,
        );

        // Update subject doc to include topic
        await _manager.addTopicReferenceToSubject(selectedSubjectId!, topicId);
      }

      else if (selectedEntryType == 'Question') {
        final qText = questionTextController.text.trim();
        if (qText.isEmpty || selectedTopicId == null || selectedSubjectId == null) {
          throw Exception("All fields must be filled");
        }

        await _manager.addMCQQuestion(
          subjectId: selectedSubjectId!,
          topicId: selectedTopicId!,
          questionText: qText,
          options: [
            optionA.text.trim(),
            optionB.text.trim(),
            optionC.text.trim(),
            optionD.text.trim(),
          ],
          correctAnswer: correctAnswer.text.trim(),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted successfully!')),
      );

      _resetForm();
      await _loadSubjects();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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

  // UI BUILDERS

  Widget _buildSubjectForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Subject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: subjectNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Subject Name',
            ),
          ),
        ],
      );

  Widget _buildTopicForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Topic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedSubjectId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Select Subject',
            ),
            items: subjects
                .map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedSubjectId = val;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: topicNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Topic Name',
            ),
          ),
        ],
      );

  Widget _buildQuestionForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add MCQ Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedSubjectId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Select Subject',
            ),
            items: subjects
                .map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedSubjectId = val;
                  selectedTopicId = null;
                  topics = [];
                });
                _loadTopics(val);
              }
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
                .map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'] as String)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedTopicId = val;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: questionTextController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Question Text',
            ),
          ),
          const SizedBox(height: 8),
          TextField(controller: optionA, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Option A')),
          const SizedBox(height: 8),
          TextField(controller: optionB, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Option B')),
          const SizedBox(height: 8),
          TextField(controller: optionC, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Option C')),
          const SizedBox(height: 8),
          TextField(controller: optionD, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Option D')),
          const SizedBox(height: 8),
          TextField(
            controller: correctAnswer,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Correct Answer (A/B/C/D)',
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                const Text('What would you like to add?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedEntryType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Entry Type',
                  ),
                  items: entryTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Submit'),
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

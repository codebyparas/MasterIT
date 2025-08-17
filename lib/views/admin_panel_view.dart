import 'package:flutter/material.dart';
import 'package:learningdart/enums/menu_action.dart';
import 'package:learningdart/services/cloud/firebase_cloud_storage.dart';
import 'package:learningdart/utilities/logout_helper.dart';
// import 'package:image_picker/image_picker.dart';

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

  String selectedQuestionType = 'MCQ';
  final List<String> questionTypes = [
    'MCQ',
    'Fill-up',
    'Match Pairs',
    'Drag & Drop',
    'Tap on Image',
    'Ordering',
  ];

  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> topics = [];
  String? selectedSubjectId;
  String? selectedTopicId;

  // Common fields
  final subjectNameController = TextEditingController();
  final topicNameController = TextEditingController();
  final questionTextController = TextEditingController();
  final hintTextController = TextEditingController();

  // MCQ
  final optionA = TextEditingController();
  final optionB = TextEditingController();
  final optionC = TextEditingController();
  final optionD = TextEditingController();
  final correctAnswer = TextEditingController(); // expects A/B/C/D

  // Fill-up
  final fillupAnswer = TextEditingController(); // can be single; extend to CSV if needed

  // Ordering
  final orderingItems = TextEditingController(); // comma-separated items

  // Match Pairs (left-right)
  final leftPairController = TextEditingController();
  final rightPairController = TextEditingController();
  final List<Map<String, String>> matchPairs = [];

  // Drag & Drop (draggable -> target)
  final dragItemController = TextEditingController();
  final dragTargetController = TextEditingController();
  final Map<String, String> dragDropMapping = {}; // key: draggable, value: target

  // Tap on Image (X,Y)
  final tapXController = TextEditingController();
  final tapYController = TextEditingController();
  final List<Map<String, int>> tapPoints = []; // store multiple; we’ll use first

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    subjectNameController.dispose();
    topicNameController.dispose();
    questionTextController.dispose();
    hintTextController.dispose();
    optionA.dispose();
    optionB.dispose();
    optionC.dispose();
    optionD.dispose();
    correctAnswer.dispose();
    fillupAnswer.dispose();
    orderingItems.dispose();
    leftPairController.dispose();
    rightPairController.dispose();
    dragItemController.dispose();
    dragTargetController.dispose();
    tapXController.dispose();
    tapYController.dispose();
    super.dispose();
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
        case 'Subject': {
          final subjectName = subjectNameController.text.trim();
          final exists = subjects.any(
            (s) => (s['name'] as String).toLowerCase() == subjectName.toLowerCase(),
          );
          if (exists) throw Exception("Subject already exists");
          await _manager.addSubject(subjectName);
          break;
        }

        case 'Topic': {
          if (selectedSubjectId == null) {
            throw Exception("Please select a subject.");
          }
          final topicName = topicNameController.text.trim();
          final duplicate = topics.any(
            (t) => (t['name'] as String).toLowerCase() == topicName.toLowerCase(),
          );
          if (duplicate) throw Exception("Topic already exists.");
          final topicId = await _manager.addTopic(
            name: topicName,
            subjectId: selectedSubjectId!,
          );
          await _manager.addTopicReferenceToSubject(selectedSubjectId!, topicId);
          break;
        }

        case 'Question': {
          if (selectedSubjectId == null || selectedTopicId == null) {
            throw Exception("Please select subject and topic.");
          }
          final qText = questionTextController.text.trim();
          final hint = hintTextController.text.trim().isEmpty
              ? null
              : hintTextController.text.trim();

          switch (selectedQuestionType) {
            case 'MCQ':
              await _manager.addMCQQuestion(
                subjectId: selectedSubjectId!,
                topicId: selectedTopicId!,
                questionText: qText,
                hintText: hint,
                options: [
                  optionA.text.trim(),
                  optionB.text.trim(),
                  optionC.text.trim(),
                  optionD.text.trim(),
                ],
                correctAnswer: correctAnswer.text.trim(), // A/B/C/D
              );
              break;

            case 'Fill-up':
              await _manager.addFillupQuestion(
                subjectId: selectedSubjectId!,
                topicId: selectedTopicId!,
                questionText: qText,
                hintText: hint,
                correctAnswers: [fillupAnswer.text.trim()],
              );
              break;

            case 'Ordering':
              final phrases = orderingItems.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              if (phrases.length < 2) {
                throw Exception("Add at least two items for ordering.");
              }
              await _manager.addOrderingQuestion(
                subjectId: selectedSubjectId!,
                topicId: selectedTopicId!,
                questionText: qText,
                hintText: hint,
                phrases: phrases,
              );
              break;

            case 'Match Pairs':
              if (matchPairs.isEmpty) {
                throw Exception("Add at least one pair.");
              }
              await _manager.addMatchPairsQuestion(
                subjectId: selectedSubjectId!,
                topicId: selectedTopicId!,
                questionText: qText,
                hintText: hint,
                pairs: matchPairs,
              );
              break;

            case 'Drag & Drop':
              if (dragDropMapping.isEmpty) {
                throw Exception("Add at least one draggable → target mapping.");
              }
              await _manager.addDragDropQuestion(
                subjectId: selectedSubjectId!,
                topicId: selectedTopicId!,
                questionText: qText,
                hintText: hint,
                mapping: Map<String, String>.from(dragDropMapping),
              );
              break;

            case 'Tap on Image':
              if (tapPoints.isEmpty) {
                throw Exception("Add at least one (X, Y) coordinate.");
              }
              final first = tapPoints.first;
              await _manager.addTapImageQuestion(
                subjectId: selectedSubjectId!,
                topicId: selectedTopicId!,
                questionText: qText,
                hintText: hint,
                x: first['x']!,
                y: first['y']!,
                imageUrl: null, // plug your uploader later
              );
              break;
          }
          break;
        }
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
    hintTextController.clear();

    optionA.clear();
    optionB.clear();
    optionC.clear();
    optionD.clear();
    correctAnswer.clear();

    fillupAnswer.clear();
    orderingItems.clear();

    leftPairController.clear();
    rightPairController.clear();
    matchPairs.clear();

    dragItemController.clear();
    dragTargetController.clear();
    dragDropMapping.clear();

    tapXController.clear();
    tapYController.clear();
    tapPoints.clear();

    setState(() {
      selectedSubjectId = null;
      selectedTopicId = null;
      topics = [];
      selectedQuestionType = 'MCQ';
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
        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
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

  Widget _buildQuestionTypeSpecificFields() {
    switch (selectedQuestionType) {
      case 'MCQ':
        return Column(
          children: [
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

      case 'Fill-up':
        return _buildFormField(
          label: 'Correct Answer',
          controller: fillupAnswer,
        );

      case 'Ordering':
        return _buildFormField(
          label: 'Items (comma separated)',
          controller: orderingItems,
        );

      case 'Match Pairs':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: leftPairController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Left value',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: rightPairController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Right value',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final l = leftPairController.text.trim();
                    final r = rightPairController.text.trim();
                    if (l.isNotEmpty && r.isNotEmpty) {
                      setState(() {
                        matchPairs.add({'left': l, 'right': r});
                        leftPairController.clear();
                        rightPairController.clear();
                      });
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            ...matchPairs.map(
              (p) => ListTile(
                title: Text("${p['left']}  ↔  ${p['right']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => matchPairs.remove(p));
                  },
                ),
              ),
            ),
          ],
        );

      case 'Drag & Drop':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dragItemController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Draggable item',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: dragTargetController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Target box',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final d = dragItemController.text.trim();
                    final t = dragTargetController.text.trim();
                    if (d.isNotEmpty && t.isNotEmpty) {
                      setState(() {
                        dragDropMapping[d] = t;
                        dragItemController.clear();
                        dragTargetController.clear();
                      });
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            ...dragDropMapping.entries.map(
              (e) => ListTile(
                title: Text("${e.key}  →  ${e.value}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => dragDropMapping.remove(e.key));
                  },
                ),
              ),
            ),
          ],
        );

      case 'Tap on Image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tapXController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'X',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: tapYController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Y',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_location_alt),
                  onPressed: () {
                    final sx = tapXController.text.trim();
                    final sy = tapYController.text.trim();
                    if (sx.isNotEmpty && sy.isNotEmpty) {
                      final x = int.tryParse(sx);
                      final y = int.tryParse(sy);
                      if (x != null && y != null) {
                        setState(() {
                          tapPoints.add({'x': x, 'y': y});
                          tapXController.clear();
                          tapYController.clear();
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...tapPoints.map(
              (pt) => ListTile(
                title: Text("x=${pt['x']}, y=${pt['y']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => tapPoints.remove(pt));
                  },
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuestionForm() => Column(
        children: [
          // Subject
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

          // Topic
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

          // Question type
          DropdownButtonFormField<String>(
            value: selectedQuestionType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Question Type',
            ),
            items: questionTypes
                .map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedQuestionType = val;
                  // Clear type-specific buffers when switching type
                  matchPairs.clear();
                  dragDropMapping.clear();
                  tapPoints.clear();
                });
              }
            },
          ),
          const SizedBox(height: 10),

          // Common fields
          _buildFormField(
            label: 'Question Text',
            controller: questionTextController,
          ),
          _buildFormField(
            label: 'Hint Text',
            controller: hintTextController,
          ),

          // Type-specific fields
          _buildQuestionTypeSpecificFields(),
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Add Entry',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Entry type picker
                  DropdownButtonFormField<String>(
                    value: selectedEntryType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Entry Type',
                    ),
                    items: entryTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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

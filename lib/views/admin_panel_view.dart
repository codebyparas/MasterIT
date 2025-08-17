import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learningdart/enums/menu_action.dart';
import 'package:learningdart/services/cloud/firebase_cloud_storage.dart';
import 'package:learningdart/utilities/logout_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://wqnxdcwwupeyiedbzfci.supabase.co';
}

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
    'Drag & Drop',
    'Tap on Image',
    'Ordering',
  ]; // <-- "Match Pairs" removed

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
  final correctAnswer = TextEditingController(); // expects A/B/C/D or full text

  // Fill-up
  final fillupAnswer = TextEditingController();

  // Ordering
  final orderingItems = TextEditingController(); // comma-separated items

  // Drag & Drop (draggable -> target)
  final dragItemController = TextEditingController();
  final dragTargetController = TextEditingController();
  final Map<String, String> dragDropMapping = {};

  // Tap on Image (X,Y)
  final tapXController = TextEditingController();
  final tapYController = TextEditingController();
  final List<Map<String, int>> tapPoints = []; // store multiple; first used

  // Image picking / upload
  final ImagePicker _picker = ImagePicker();
  List<XFile> _pickedImages = [];
  bool _isUploadingImages = false;

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

  // ---------------- Image picker & upload ----------------

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) {
        setState(() {
          _pickedImages = picked;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image pick error: $e')));
    }
  }

  Future<List<String>> _uploadPickedImages() async {
    // Upload picked images to Supabase storage 'photos' bucket and return list of public URLs.
    // NOTE: Ensure Supabase.initialize(...) was called in main() and the bucket 'photos' exists & is public.
    if (_pickedImages.isEmpty) return [];

    setState(() => _isUploadingImages = true);
    final supabase = Supabase.instance.client;
    final bucket = 'photos';
    final uuid = const Uuid();
    final List<String> uploadedUrls = [];

    try {
      for (final xfile in _pickedImages) {
        // Create a file object from the picked image
        final file = File(xfile.path);
        final filename = '${uuid.v4()}_${xfile.name}';
        final destination = 'questions/$filename';

        try {
          // This call may vary by supabase_flutter version.
          // The common approach: upload file (File) and then request public URL.
          // If your supabase version exposes `uploadBinary`, use that API.
          // If not, `upload` with File should work.
          await supabase.storage.from(bucket).upload(destination, file);

          // Get public URL (API surface may differ per version)
          final publicRes = supabase.storage
              .from(bucket)
              .getPublicUrl(destination);

          // publicRes might be a String or a Response object depending on version; handle common cases:
          String? url;
          url = publicRes;
          if (url.isEmpty) {
            // fallback construct (works if storage is at <SUPABASE_URL>/storage/v1/object/public/<bucket>/<path>)
            final supaUrl = SupabaseConfig.supabaseUrl;
            url = '$supaUrl/storage/v1/object/public/$bucket/$destination';
          }

          uploadedUrls.add(url);
        } catch (uploadErr) {
          // don't fail the whole batch; continue with others, but surface message
          debugPrint('Upload error for ${xfile.name}: $uploadErr');
        }
      }
    } finally {
      setState(() => _isUploadingImages = false);
    }

    return uploadedUrls;
  }

  // ---------------- Submit handler ----------------

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);
    try {
      switch (selectedEntryType) {
        case 'Subject':
          {
            final subjectName = subjectNameController.text.trim();
            final exists = subjects.any(
              (s) =>
                  (s['name'] as String).toLowerCase() ==
                  subjectName.toLowerCase(),
            );
            if (exists) throw Exception("Subject already exists");
            await _manager.addSubject(subjectName);
            break;
          }

        case 'Topic':
          {
            if (selectedSubjectId == null) {
              throw Exception("Please select a subject.");
            }
            final topicName = topicNameController.text.trim();
            final duplicate = topics.any(
              (t) =>
                  (t['name'] as String).toLowerCase() ==
                  topicName.toLowerCase(),
            );
            if (duplicate) throw Exception("Topic already exists.");

            final topicId = await _manager.addTopic(
              name: topicName,
              subjectId: selectedSubjectId!,
            );

            // Note: we are using normalized schema (topics reference subjectId). No subject-topics array.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Topic created (id: $topicId)')),
            );
            break;
          }

        case 'Question':
          {
            if (selectedSubjectId == null || selectedTopicId == null) {
              throw Exception("Please select subject and topic.");
            }

            final qText = questionTextController.text.trim();
            final hint = hintTextController.text.trim().isEmpty
                ? null
                : hintTextController.text.trim();

            // Upload images first (if any) to Supabase and get public URLs
            final uploadedUrls = await _uploadPickedImages();

            switch (selectedQuestionType) {
              case 'MCQ':
                {
                  final options = [
                    optionA.text.trim(),
                    optionB.text.trim(),
                    optionC.text.trim(),
                    optionD.text.trim(),
                  ];
                  // Normalize correct answer letter (A/B/...) to actual option text if letter provided
                  String normalizedCorrect = correctAnswer.text.trim();
                  final letter = normalizedCorrect.toUpperCase();
                  if (letter.length == 1 &&
                      letter.codeUnitAt(0) >= 65 &&
                      letter.codeUnitAt(0) < 65 + options.length) {
                    normalizedCorrect = options[letter.codeUnitAt(0) - 65];
                  }

                  await _manager.addQuestion(
                    type: 'mcq',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    questionText: qText,
                    hintText: hint,
                    correctAnswer: normalizedCorrect,
                    options: options,
                    images: uploadedUrls,
                  );
                  break;
                }

              case 'Fill-up':
                {
                  final answers = [fillupAnswer.text.trim()];
                  await _manager.addQuestion(
                    type: 'fillup',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    questionText: qText,
                    hintText: hint,
                    correctAnswer: answers,
                    images: uploadedUrls,
                  );
                  break;
                }

              case 'Ordering':
                {
                  final phrases = orderingItems.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  if (phrases.length < 2)
                    throw Exception("Add at least two items for ordering.");

                  await _manager.addQuestion(
                    type: 'ordering',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    questionText: qText,
                    hintText: hint,
                    correctAnswer: phrases,
                    options: phrases,
                    images: uploadedUrls,
                  );
                  break;
                }

              case 'Drag & Drop':
                {
                  if (dragDropMapping.isEmpty)
                    throw Exception(
                      "Add at least one draggable → target mapping.",
                    );
                  final draggables = dragDropMapping.keys.toList();
                  final boxes = dragDropMapping.values.toSet().toList();

                  // We'll store mapping inside correctAnswer as a structured Map.
                  // Later firebase_cloud_storage.dart can be adjusted to extract 'draggables'/'boxes' fields separately if desired.
                  final answerPayload = {
                    'mapping': Map<String, String>.from(dragDropMapping),
                    'draggables': draggables,
                    'boxes': boxes,
                  };

                  await _manager.addQuestion(
                    type: 'drag_drop',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    questionText: qText,
                    hintText: hint,
                    correctAnswer: answerPayload,
                    images: uploadedUrls,
                  );
                  break;
                }

              case 'Tap on Image':
                {
                  if (tapPoints.isEmpty)
                    throw Exception("Add at least one (X, Y) coordinate.");
                  final first = tapPoints.first;
                  await _manager.addQuestion(
                    type: 'tap_image',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    questionText: qText,
                    hintText: hint,
                    correctCoordinates: {'x': first['x']!, 'y': first['y']!},
                    images: uploadedUrls,
                  );
                  break;
                }

              default:
                throw Exception(
                  'Unsupported question type: $selectedQuestionType',
                );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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

    dragItemController.clear();
    dragTargetController.clear();
    dragDropMapping.clear();

    tapXController.clear();
    tapYController.clear();
    tapPoints.clear();

    _pickedImages = [];

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
        validator: (val) =>
            val == null || val.trim().isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildSubjectForm() =>
      _buildFormField(label: 'Subject Name', controller: subjectNameController);

  Widget _buildTopicForm() => Column(
    children: [
      DropdownButtonFormField<String>(
        value: selectedSubjectId,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Subject',
        ),
        items: subjects
            .map(
              (s) => DropdownMenuItem(
                value: s['id'] as String,
                child: Text(s['name'] as String),
              ),
            )
            .toList(),
        onChanged: (val) {
          setState(() => selectedSubjectId = val);
          if (val != null) _loadTopics(val);
        },
      ),
      const SizedBox(height: 10),
      _buildFormField(label: 'Topic Name', controller: topicNameController),
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
              label: 'Correct Answer (A/B/C/D or full text)',
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
                ),
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Add Images'),
              onPressed: _pickImages,
            ),
            const SizedBox(width: 12),
            if (_isUploadingImages) const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 8),
        if (_pickedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final xfile = _pickedImages[idx];
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(xfile.path),
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _pickedImages.removeAt(idx);
                          });
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionForm() => Column(
    children: [
      DropdownButtonFormField<String>(
        value: selectedSubjectId,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Subject',
        ),
        items: subjects
            .map(
              (s) => DropdownMenuItem(
                value: s['id'] as String,
                child: Text(s['name'] as String),
              ),
            )
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
            .map(
              (t) => DropdownMenuItem(
                value: t['id'] as String,
                child: Text(t['name'] as String),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => selectedTopicId = val),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: selectedQuestionType,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Question Type',
        ),
        items: questionTypes
            .map((q) => DropdownMenuItem(value: q, child: Text(q)))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              selectedQuestionType = val;
              // Clear type-specific buffers when switching type
              dragDropMapping.clear();
              tapPoints.clear();
            });
          }
        },
      ),
      const SizedBox(height: 10),
      _buildFormField(
        label: 'Question Text',
        controller: questionTextController,
      ),
      _buildFormField(label: 'Hint Text', controller: hintTextController),

      // images picker (available for EVERY question type)
      const SizedBox(height: 10),
      _buildImagePicker(),
      const SizedBox(height: 10),

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
              PopupMenuItem(value: MenuAction.logout, child: Text("Logout")),
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
                          _pickedImages = [];
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

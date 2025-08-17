// admin_panel_view.dart
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
  // keep anon key / other secrets elsewhere (env/dart-define).
}

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> {
  final _manager = FirebaseCloudStorage();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  String selectedEntryType = 'Subject';
  final List<String> entryTypes = ['Subject', 'Topic', 'Question'];

  String selectedQuestionType = 'MCQ';
  final List<String> questionTypes = [
    'MCQ',
    'Fill-up',
    'Drag & Drop',
    'Tap on Image',
    'Ordering',
  ]; // "Match Pairs" removed from global dropdown per your request.

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

  // MCQ match-pairs inside MCQ (new)
  final mcqLeftPairController = TextEditingController();
  final mcqRightPairController = TextEditingController();
  final List<Map<String, String>> mcqMatchPairs = [];

  // Fill-up
  final fillupAnswer = TextEditingController();

  // Ordering
  final orderingItems = TextEditingController(); // comma-separated items

  // Drag & Drop (we'll support text or images)
  final dragItemController =
      TextEditingController(); // used when adding a text draggable
  final dragTargetController =
      TextEditingController(); // used when adding a text target

  // We'll keep a list of mapping entries; each mapping entry:
  // {
  //   'draggable': {'type':'text'|'image', 'value':String (text or tempPath)},
  //   'target': {'type':'text'|'image', 'value':String (text or tempPath)}
  // }
  final List<Map<String, dynamic>> dragMappings = [];

  // Temporary picked image for a draggable/target before adding to mapping:
  XFile? _tempDraggableImage;
  XFile? _tempTargetImage;

  // Tap on Image (X,Y)
  final tapXController = TextEditingController();
  final tapYController = TextEditingController();
  final List<Map<String, int>> tapPoints =
      []; // store multiple; we'll use first if present

  // Question-level images (picked via "Add Images" button)
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

    mcqLeftPairController.dispose();
    mcqRightPairController.dispose();

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

  // ---------------- Image picker & upload helpers ----------------

  Future<void> _pickQuestionImages() async {
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

  Future<void> _pickTempDraggableImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _tempDraggableImage = picked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image pick error: $e')),
      );
    }
  }
  
  Future<void> _pickTempTargetImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _tempTargetImage = picked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image pick error: $e')),
      );
    }
  }

  /// Upload a list of XFile files to Supabase 'photos' bucket and return a map path->publicUrl.
  /// NOTE: Supabase upload / getPublicUrl method signatures differ across versions.
  /// This implements a commonly-used approach; adjust if your `supabase_flutter` version requires alternate API.
  Future<Map<String, String>> _uploadFilesToSupabase(List<XFile> files) async {
    final supabase = Supabase.instance.client;
    const bucket = 'photos';
    final Map<String, String> result = {};
    setState(() => _isUploadingImages = true);

    try {
      for (final file in files) {
        try {
          final fname = '${_uuid.v4()}_${file.name}';
          final destination = 'questions/$fname';
          final f = File(file.path);

          // upload - API can be: supabase.storage.from(bucket).upload(destination, f)
          // or uploadBinary, etc. Use your version's upload method.
          await supabase.storage.from(bucket).upload(destination, f);

          // get public url
          // many versions: supabase.storage.from(bucket).getPublicUrl(destination) returns String
          // if it returns object, adjust accordingly.
          final publicRes = supabase.storage
              .from(bucket)
              .getPublicUrl(destination);

          String? url;
          url = publicRes;

          result[file.path] = url;
        } catch (uploadErr) {
          debugPrint('Upload error (${file.name}): $uploadErr');
        }
      }
    } finally {
      setState(() => _isUploadingImages = false);
    }

    return result;
  }

  // ---------------- Drag & Drop mappings helpers ----------------

  void _addDragMappingFromCurrentInputs() {
    final leftText = dragItemController.text.trim();
    final rightText = dragTargetController.text.trim();

    if ((leftText.isEmpty && _tempDraggableImage == null) ||
        (rightText.isEmpty && _tempTargetImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Provide text or select image for both draggable and target.',
          ),
        ),
      );
      return;
    }

    final draggable = _tempDraggableImage != null
        ? {'type': 'image', 'file': _tempDraggableImage}
        : {'type': 'text', 'value': leftText};

    final target = _tempTargetImage != null
        ? {'type': 'image', 'file': _tempTargetImage}
        : {'type': 'text', 'value': rightText};

    setState(() {
      dragMappings.add({'draggable': draggable, 'target': target});
      // reset temp inputs
      dragItemController.clear();
      dragTargetController.clear();
      _tempDraggableImage = null;
      _tempTargetImage = null;
    });
  }

  void _removeDragMapping(int idx) {
    setState(() => dragMappings.removeAt(idx));
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

            // Collect all images that need upload (question-level + images used in dragMappings).
            final Set<XFile> allFiles = {..._pickedImages};
            for (final m in dragMappings) {
              final draggable = m['draggable'] as Map<String, dynamic>;
              final target = m['target'] as Map<String, dynamic>;
              if (draggable['type'] == 'image' && draggable['file'] is XFile) {
                allFiles.add(draggable['file'] as XFile);
              }
              if (target['type'] == 'image' && target['file'] is XFile) {
                allFiles.add(target['file'] as XFile);
              }
            }

            // Upload all image files and obtain path->url map.
            final fileToUrl = await _uploadFilesToSupabase(allFiles.toList());

            // Build a list of question-level image urls (from _pickedImages)
            final List<String> questionImageUrls = _pickedImages
                .map((f) => fileToUrl[f.path])
                .whereType<String>()
                .toList();

            // Now handle question types
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

                  // Prepare match pairs for MCQ (if any)
                  final List<Map<String, String>> matchPairsForMCQ =
                      mcqMatchPairs
                          .map(
                            (p) => {'left': p['left']!, 'right': p['right']!},
                          )
                          .toList();

                  await _manager.addQuestion(
                    type: 'mcq',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    questionText: qText,
                    hintText: hint,
                    correctAnswer: normalizedCorrect,
                    options: options,
                    images: questionImageUrls,
                    matchPair: matchPairsForMCQ.isEmpty
                        ? null
                        : matchPairsForMCQ,
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
                    images: questionImageUrls,
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
                    images: questionImageUrls,
                  );
                  break;
                }

              case 'Drag & Drop':
                {
                  if (dragMappings.isEmpty)
                    throw Exception(
                      "Add at least one draggable → target mapping.",
                    );

                  // Transform mappings into final mapping structure with uploaded URLs for images.
                  final List<Map<String, dynamic>> mappingPayload = [];
                  final List<dynamic> draggablesFlattened = [];
                  final List<dynamic> boxesFlattened = [];

                  for (final m in dragMappings) {
                    final draggable = m['draggable'] as Map<String, dynamic>;
                    final target = m['target'] as Map<String, dynamic>;

                    dynamic leftValue;
                    dynamic rightValue;

                    if (draggable['type'] == 'image' &&
                        draggable['file'] is XFile) {
                      leftValue = fileToUrl[(draggable['file'] as XFile).path];
                    } else {
                      leftValue = draggable['value'] as String;
                    }

                    if (target['type'] == 'image' && target['file'] is XFile) {
                      rightValue = fileToUrl[(target['file'] as XFile).path];
                    } else {
                      rightValue = target['value'] as String;
                    }

                    mappingPayload.add({
                      'left': leftValue,
                      'right': rightValue,
                    });
                    draggablesFlattened.add(leftValue);
                    boxesFlattened.add(rightValue);
                  }

                  // For drag & drop we store a structured correctAnswer (mapping + flattened lists)
                  final answerPayload = {
                    'mapping': mappingPayload,
                    'draggables': draggablesFlattened,
                    'boxes': boxesFlattened,
                  };

                  // include question-level images + any uploaded mapping images (deduplicated)
                  final Set<String> allImageUrls = {...questionImageUrls};
                  for (final url in fileToUrl.values) {
                    if (url != null) allImageUrls.add(url);
                  }

                  await _manager.addQuestion(
                    type: 'drag_drop',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    questionText: qText,
                    hintText: hint,
                    correctAnswer: answerPayload,
                    images: allImageUrls.toList(),
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
                    images: questionImageUrls,
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

    mcqLeftPairController.clear();
    mcqRightPairController.clear();
    mcqMatchPairs.clear();

    fillupAnswer.clear();
    orderingItems.clear();

    dragItemController.clear();
    dragTargetController.clear();
    dragMappings.clear();
    _tempDraggableImage = null;
    _tempTargetImage = null;

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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Add Images'),
              onPressed: _pickQuestionImages,
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
                          setState(() => _pickedImages.removeAt(idx));
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

  Widget _buildQuestionTypeSpecificFields() {
    switch (selectedQuestionType) {
      case 'MCQ':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormField(label: 'Option A', controller: optionA),
            _buildFormField(label: 'Option B', controller: optionB),
            _buildFormField(label: 'Option C', controller: optionC),
            _buildFormField(label: 'Option D', controller: optionD),
            _buildFormField(
              label: 'Correct Answer (A/B/C/D or full text)',
              controller: correctAnswer,
            ),
            const SizedBox(height: 8),
            // MCQ-match-pairs builder
            const Text(
              'Optional: Add match pair(s) for this MCQ (left ↔ right)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mcqLeftPairController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Left',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: mcqRightPairController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Right',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final l = mcqLeftPairController.text.trim();
                    final r = mcqRightPairController.text.trim();
                    if (l.isNotEmpty && r.isNotEmpty) {
                      setState(() {
                        mcqMatchPairs.add({'left': l, 'right': r});
                        mcqLeftPairController.clear();
                        mcqRightPairController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...mcqMatchPairs.map(
              (p) => ListTile(
                title: Text("${p['left']}  ↔  ${p['right']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => mcqMatchPairs.remove(p));
                  },
                ),
              ),
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
            const Text(
              'Add draggable → target pair (each can be text OR an image)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dragItemController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Draggable (text)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Pick image for draggable',
                  icon: const Icon(Icons.image),
                  onPressed: _pickTempDraggableImage,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: dragTargetController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Target (text)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Pick image for target',
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _pickTempTargetImage,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addDragMappingFromCurrentInputs,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // show pending chosen images (if any)
            if (_tempDraggableImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Text('Pending draggable image:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.file(
                        File(_tempDraggableImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          setState(() => _tempDraggableImage = null),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ),
            if (_tempTargetImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Text('Pending target image:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.file(
                        File(_tempTargetImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _tempTargetImage = null),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // list mapping entries
            const Text(
              'Mappings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...dragMappings.asMap().entries.map((entry) {
              final idx = entry.key;
              final map = entry.value;
              final draggable = map['draggable'] as Map<String, dynamic>;
              final target = map['target'] as Map<String, dynamic>;

              Widget leftWidget;
              if (draggable['type'] == 'image' && draggable['file'] is XFile) {
                leftWidget = SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.file(
                    File((draggable['file'] as XFile).path),
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                leftWidget = Text(draggable['value'] ?? '');
              }

              Widget rightWidget;
              if (target['type'] == 'image' && target['file'] is XFile) {
                rightWidget = SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.file(
                    File((target['file'] as XFile).path),
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                rightWidget = Text(target['value'] ?? '');
              }

              return ListTile(
                title: Row(
                  children: [
                    Expanded(child: leftWidget),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward),
                    const SizedBox(width: 8),
                    Expanded(child: rightWidget),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeDragMapping(idx),
                ),
              );
            }),
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
                  onPressed: () => setState(() => tapPoints.remove(pt)),
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
              dragMappings.clear();
              _tempDraggableImage = null;
              _tempTargetImage = null;
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

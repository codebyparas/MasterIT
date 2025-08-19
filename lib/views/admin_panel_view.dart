// admin_panel_view.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learningdart/enums/menu_action.dart';
import 'package:learningdart/services/cloud/firebase_cloud_storage.dart';
import 'package:learningdart/utilities/logout_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Adjust the path below to where your rectangle_selector.dart lives in your project.
import 'package:learningdart/utilities/rectangle_selector.dart';

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
  final List<String> entryTypes = ['Subject', 'Topic', 'Concept', 'Question'];

  String selectedQuestionType = 'MCQ';
  final List<String> questionTypes = [
    'MCQ',
    'Fill-up',
    'Drag & Drop',
    'Tap on Image',
    'Ordering',
  ];

  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> topics = [];
  List<Map<String, dynamic>> concepts = [];
  String? selectedSubjectId;
  String? selectedTopicId;
  String? selectedConceptId;

  // Common fields
  final subjectNameController = TextEditingController();
  final topicNameController = TextEditingController();
  final conceptNameController = TextEditingController();
  final questionTextController = TextEditingController();
  final hintTextController = TextEditingController();

  // MCQ
  final optionA = TextEditingController();
  final optionB = TextEditingController();
  final optionC = TextEditingController();
  final optionD = TextEditingController();
  final correctAnswer = TextEditingController();

  // MCQ match-pairs inside MCQ (optional)
  final mcqLeftPairController = TextEditingController();
  final mcqRightPairController = TextEditingController();
  final List<Map<String, String>> mcqMatchPairs = [];

  // Fill-up
  final fillupAnswer = TextEditingController();

  // Ordering
  final orderingItems = TextEditingController();

  // Drag & Drop
  final dragItemController = TextEditingController();
  final dragTargetController = TextEditingController();
  final List<Map<String, dynamic>> dragMappings = [];
  XFile? _tempDraggableImage;
  XFile? _tempTargetImage;

  // Tap on Image - allow manual or drawn rectangle
  final tapXController = TextEditingController();
  final tapYController = TextEditingController();
  final tapWController = TextEditingController();
  final tapHController = TextEditingController();
  final List<Map<String, int>> tapPoints = [];

  // Rectangle from drawing (pixel coordinates)
  Map<String, int>? _tapRectPixels;

  // Question-level images
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
    conceptNameController.dispose();
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
    tapWController.dispose();
    tapHController.dispose();

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

  Future<void> _loadConcepts(String topicId) async {
    final data = await _manager.getConcepts(topicId);
    setState(() {
      concepts = data;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image pick error: $e')),
      );
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

  /// Upload list of XFile files to Supabase 'photos' bucket and return map path->publicUrl.
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

          await supabase.storage.from(bucket).upload(destination, f);

          final publicRes = supabase.storage.from(bucket).getPublicUrl(destination);
          String? url = publicRes;
          if (url.isEmpty) {
            url = '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/$bucket/$destination';
          }
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

  // ---------------- Drag & Drop helpers ----------------

  void _addDragMappingFromCurrentInputs() {
    final leftText = dragItemController.text.trim();
    final rightText = dragTargetController.text.trim();

    if ((leftText.isEmpty && _tempDraggableImage == null) ||
        (rightText.isEmpty && _tempTargetImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provide text or select image for both draggable and target.'),
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
      dragItemController.clear();
      dragTargetController.clear();
      _tempDraggableImage = null;
      _tempTargetImage = null;
    });
  }

  void _removeDragMapping(int idx) {
    setState(() => dragMappings.removeAt(idx));
  }

  // ---------------- Rectangle selector integration ----------------

  Future<Size> _getImagePixelSize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => completer.complete(img));
    final img = await completer.future;
    return Size(img.width.toDouble(), img.height.toDouble());
  }

  /// Open rectangle selector page and handle the normalized coordinates returned
  Future<void> _openRectangleSelectorForImage(XFile imageFile) async {
    try {
      final result = await Navigator.of(context).push<Map<String, double>>(
        MaterialPageRoute(
          builder: (_) => RectangleSelectorPage(imagePath: imageFile.path),
        ),
      );

      if (result == null) return;

      // Rectangle selector returns Map<String, double> with keys: 'x', 'y', 'width', 'height'
      // These are normalized coordinates (0.0 to 1.0) relative to the intrinsic image size
      if (!result.containsKey('x') || !result.containsKey('y') || 
          !result.containsKey('width') || !result.containsKey('height')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid rectangle data received.')),
        );
        return;
      }

      final normalizedX = result['x']!;
      final normalizedY = result['y']!;
      final normalizedWidth = result['width']!;
      final normalizedHeight = result['height']!;

      // Convert normalized coordinates to pixel coordinates
      final imgSize = await _getImagePixelSize(imageFile.path);
      final px = (normalizedX * imgSize.width).round();
      final py = (normalizedY * imgSize.height).round();
      final pw = (normalizedWidth * imgSize.width).round();
      final ph = (normalizedHeight * imgSize.height).round();

      // Clamp to image bounds
      final clampedX = px.clamp(0, imgSize.width.toInt());
      final clampedY = py.clamp(0, imgSize.height.toInt());
      final maxWidth = imgSize.width.toInt() - clampedX;
      final maxHeight = imgSize.height.toInt() - clampedY;
      final clampedW = pw.clamp(1, maxWidth);
      final clampedH = ph.clamp(1, maxHeight);

      setState(() {
        _tapRectPixels = {
          'x': clampedX,
          'y': clampedY,
          'w': clampedW,
          'h': clampedH,
        };
        tapXController.text = clampedX.toString();
        tapYController.text = clampedY.toString();
        tapWController.text = clampedW.toString();
        tapHController.text = clampedH.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rectangle selected and coordinates updated!')),
      );
    } catch (e) {
      debugPrint('Rectangle selector error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rectangle selection error: $e')),
      );
    }
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
              (s) => (s['name'] as String).toLowerCase() == subjectName.toLowerCase(),
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
              (t) => (t['name'] as String).toLowerCase() == topicName.toLowerCase(),
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

        case 'Concept':
          {
            if (selectedSubjectId == null || selectedTopicId == null) {
              throw Exception("Please select subject and topic.");
            }
            final conceptName = conceptNameController.text.trim();
            if (conceptName.isEmpty) throw Exception("Concept name is required.");

            final conceptId = await _manager.addConcept(
              name: conceptName,
              subjectId: selectedSubjectId!,
              topicId: selectedTopicId!,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Concept created (id: $conceptId)')),
            );
            break;
          }

        case 'Question':
          {
            if (selectedSubjectId == null || selectedTopicId == null) {
              throw Exception("Please select subject and topic.");
            }
            if (selectedConceptId == null) {
              throw Exception("Please select a concept (required).");
            }

            final qText = questionTextController.text.trim();
            final hint = hintTextController.text.trim().isEmpty
                ? null
                : hintTextController.text.trim();

            // Gather files to upload
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

            final fileToUrl = await _uploadFilesToSupabase(allFiles.toList());

            final List<String> questionImageUrls = _pickedImages
                .map((f) => fileToUrl[f.path])
                .whereType<String>()
                .toList();

            final conceptIdForQuestion = selectedConceptId!;

            switch (selectedQuestionType) {
              case 'MCQ':
                {
                  final options = [
                    optionA.text.trim(),
                    optionB.text.trim(),
                    optionC.text.trim(),
                    optionD.text.trim(),
                  ];
                  String normalizedCorrect = correctAnswer.text.trim();
                  final letter = normalizedCorrect.toUpperCase();
                  if (letter.length == 1 &&
                      letter.codeUnitAt(0) >= 65 &&
                      letter.codeUnitAt(0) < 65 + options.length) {
                    normalizedCorrect = options[letter.codeUnitAt(0) - 65];
                  }

                  final List<Map<String, String>> matchPairsForMCQ = mcqMatchPairs
                      .map((p) => {'left': p['left']!, 'right': p['right']!})
                      .toList();

                  await _manager.addQuestion(
                    type: 'mcq',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    conceptId: conceptIdForQuestion,
                    questionText: qText,
                    hintText: hint,
                    correctAnswer: normalizedCorrect,
                    options: options,
                    images: questionImageUrls,
                    matchPair: matchPairsForMCQ.isEmpty ? null : matchPairsForMCQ,
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
                    conceptId: conceptIdForQuestion,
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
                  if (phrases.length < 2) {
                    throw Exception("Add at least two items for ordering.");
                  }

                  await _manager.addQuestion(
                    type: 'ordering',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    conceptId: conceptIdForQuestion,
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
                  if (dragMappings.isEmpty) {
                    throw Exception("Add at least one draggable → target mapping.");
                  }

                  final List<Map<String, dynamic>> mappingPayload = [];
                  final List<dynamic> draggablesFlattened = [];
                  final List<dynamic> boxesFlattened = [];

                  for (final m in dragMappings) {
                    final draggable = m['draggable'] as Map<String, dynamic>;
                    final target = m['target'] as Map<String, dynamic>;

                    dynamic leftValue;
                    dynamic rightValue;

                    if (draggable['type'] == 'image' && draggable['file'] is XFile) {
                      leftValue = fileToUrl[(draggable['file'] as XFile).path];
                    } else {
                      leftValue = draggable['value'] as String;
                    }

                    if (target['type'] == 'image' && target['file'] is XFile) {
                      rightValue = fileToUrl[(target['file'] as XFile).path];
                    } else {
                      rightValue = target['value'] as String;
                    }

                    mappingPayload.add({'left': leftValue, 'right': rightValue});
                    draggablesFlattened.add(leftValue);
                    boxesFlattened.add(rightValue);
                  }

                  final answerPayload = {
                    'mapping': mappingPayload,
                    'draggables': draggablesFlattened,
                    'boxes': boxesFlattened,
                  };

                  final Set<String> allImageUrls = {...questionImageUrls};
                  for (final url in fileToUrl.values) {
                    allImageUrls.add(url);
                  }

                  await _manager.addQuestion(
                    type: 'drag_drop',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    conceptId: conceptIdForQuestion,
                    questionText: qText,
                    hintText: hint,
                    correctAnswer: answerPayload,
                    images: allImageUrls.toList(),
                  );
                  break;
                }

              case 'Tap on Image':
                {
                  // Prefer the rectangle if provided
                  Map<String, int>? coords;

                  if (_tapRectPixels != null) {
                    coords = _tapRectPixels;
                  } else if (tapXController.text.isNotEmpty &&
                      tapYController.text.isNotEmpty &&
                      tapWController.text.isNotEmpty &&
                      tapHController.text.isNotEmpty) {
                    final px = int.tryParse(tapXController.text.trim());
                    final py = int.tryParse(tapYController.text.trim());
                    final pw = int.tryParse(tapWController.text.trim());
                    final ph = int.tryParse(tapHController.text.trim());
                    if (px == null || py == null || pw == null || ph == null) {
                      throw Exception('Invalid rectangle numeric values.');
                    }
                    coords = {'x': px, 'y': py, 'w': pw, 'h': ph};
                  } else if (tapPoints.isNotEmpty) {
                    // fallback to single tap point
                    final first = tapPoints.first;
                    coords = {'x': first['x']!, 'y': first['y']!, 'w': 1, 'h': 1};
                  } else {
                    throw Exception(
                        "Provide rectangle (draw or enter x,y,w,h) or at least one tap point.");
                  }

                  if (questionImageUrls.isEmpty) {
                    throw Exception(
                        "Please add at least one image for Tap on Image question.");
                  }

                  await _manager.addQuestion(
                    type: 'tap_image',
                    subjectId: selectedSubjectId!,
                    topicId: selectedTopicId!,
                    conceptId: conceptIdForQuestion,
                    questionText: qText,
                    hintText: hint,
                    correctCoordinates: coords,
                    images: questionImageUrls,
                  );
                  break;
                }

              default:
                throw Exception('Unsupported question type: $selectedQuestionType');
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
    conceptNameController.clear();
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
    tapWController.clear();
    tapHController.clear();
    tapPoints.clear();
    _tapRectPixels = null;

    _pickedImages = [];

    setState(() {
      selectedSubjectId = null;
      selectedTopicId = null;
      selectedConceptId = null;
      topics = [];
      concepts = [];
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
          _buildFormField(label: 'Topic Name', controller: topicNameController),
        ],
      );

  Widget _buildConceptForm() => Column(
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
          _buildFormField(label: 'Concept Name', controller: conceptNameController),
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
                        onTap: () => setState(() => _pickedImages.removeAt(idx)),
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
                  onPressed: () => setState(() => mcqMatchPairs.remove(p)),
                ),
              ),
            ),
          ],
        );

      case 'Fill-up':
        return _buildFormField(label: 'Correct Answer', controller: fillupAnswer);

      case 'Ordering':
        return _buildFormField(label: 'Items (comma separated)', controller: orderingItems);

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
                      child: Image.file(File(_tempDraggableImage!.path), fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _tempDraggableImage = null),
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
                      child: Image.file(File(_tempTargetImage!.path), fit: BoxFit.cover),
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
            const Text('Mappings', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  child: Image.file(File((draggable['file'] as XFile).path), fit: BoxFit.cover),
                );
              } else {
                leftWidget = Text(draggable['value'] ?? '');
              }

              Widget rightWidget;
              if (target['type'] == 'image' && target['file'] is XFile) {
                rightWidget = SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.file(File((target['file'] as XFile).path), fit: BoxFit.cover),
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
            const Text(
              'Define correct area: either draw a rectangle on the image OR enter x,y,w,h (pixels).',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.crop_square),
                  label: const Text('Draw rectangle'),
                  onPressed: () {
                    if (_pickedImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pick an image first (Add Images).')),
                      );
                      return;
                    }
                    // Use first picked image for rectangle drawing
                    _openRectangleSelectorForImage(_pickedImages.first);
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear rectangle'),
                  onPressed: () {
                    setState(() {
                      _tapRectPixels = null;
                      tapXController.clear();
                      tapYController.clear();
                      tapWController.clear();
                      tapHController.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: tapXController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'X (px)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: tapYController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Y (px)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: tapWController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'W (px)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: tapHController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'H (px)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Use manual rect'),
                  onPressed: () {
                    final sx = tapXController.text.trim();
                    final sy = tapYController.text.trim();
                    final sw = tapWController.text.trim();
                    final sh = tapHController.text.trim();
                    final px = int.tryParse(sx);
                    final py = int.tryParse(sy);
                    final pw = int.tryParse(sw);
                    final ph = int.tryParse(sh);
                    if (px == null || py == null || pw == null || ph == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter valid numbers for x,y,w,h')),
                      );
                      return;
                    }
                    setState(() {
                      _tapRectPixels = {'x': px, 'y': py, 'w': pw, 'h': ph};
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Manual rectangle saved.')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_tapRectPixels != null)
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Selected rectangle: x=${_tapRectPixels!['x']}, y=${_tapRectPixels!['y']}, '
                    'w=${_tapRectPixels!['w']}, h=${_tapRectPixels!['h']}',
                  ),
                ),
              ),
            const SizedBox(height: 12),
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
                .map((s) => DropdownMenuItem(
                      value: s['id'] as String,
                      child: Text(s['name'] as String),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                selectedSubjectId = val;
                selectedTopicId = null;
                concepts = [];
                selectedConceptId = null;
              });
              if (val != null) _loadTopics(val);
            },
            validator: (v) => v == null ? 'Please select a subject' : null,
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
            onChanged: (val) {
              setState(() {
                selectedTopicId = val;
                selectedConceptId = null;
                concepts = [];
              });
              if (val != null) _loadConcepts(val);
            },
            validator: (v) => v == null ? 'Please select a topic' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedConceptId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Select Concept (required)',
            ),
            items: concepts
                .map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name'] as String),
                    ))
                .toList(),
            onChanged: (val) => setState(() => selectedConceptId = val),
            validator: (v) => v == null ? 'Please select a concept' : null,
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
                  dragMappings.clear();
                  _tempDraggableImage = null;
                  _tempTargetImage = null;
                  tapPoints.clear();
                  _tapRectPixels = null;
                  tapXController.clear();
                  tapYController.clear();
                  tapWController.clear();
                  tapHController.clear();
                });
              }
            },
          ),
          const SizedBox(height: 10),
          _buildFormField(label: 'Question Text', controller: questionTextController),
          _buildFormField(label: 'Hint Text', controller: hintTextController),
          const SizedBox(height: 10),
          _buildImagePicker(),
          const SizedBox(height: 10),
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
                          selectedConceptId = null;
                          topics = [];
                          concepts = [];
                          _pickedImages = [];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (selectedEntryType == 'Subject') _buildSubjectForm(),
                  if (selectedEntryType == 'Topic') _buildTopicForm(),
                  if (selectedEntryType == 'Concept') _buildConceptForm(),
                  if (selectedEntryType == 'Question') _buildQuestionForm(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Text("Submit"),
                      onPressed: isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:learningdart/models/quiz_models.dart';

class Region {
  final String name;
  final Rect bounds;

  Region({required this.name, required this.bounds});
}

class QuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final Function(dynamic) onAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final bool showCorrectAnswer;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.isAnswered,
    required this.isCorrect,
    required this.showCorrectAnswer,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case 'mcq':
        return MCQWidget(
          question: question,
          onAnswer: onAnswer,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showCorrectAnswer: showCorrectAnswer,
        );
      case 'fillup':
        return FillUpWidget(
          question: question,
          onAnswer: onAnswer,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showCorrectAnswer: showCorrectAnswer,
        );
      case 'ordering':
        return OrderingWidget(
          question: question,
          onAnswer: onAnswer,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showCorrectAnswer: showCorrectAnswer,
        );
      case 'drag_drop':
        return DragDropWidget(
          question: question,
          onAnswer: onAnswer,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showCorrectAnswer: showCorrectAnswer,
        );
      case 'tap_image':
        return TapImageWidget(
          question: question,
          onAnswer: onAnswer,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showCorrectAnswer: showCorrectAnswer,
        );
      default:
        return const Center(child: Text('Unsupported question type'));
    }
  }
}

// Fixed MCQ Widget with proper state management
class MCQWidget extends StatefulWidget {
  final QuizQuestion question;
  final Function(dynamic) onAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final bool showCorrectAnswer;

  const MCQWidget({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.isAnswered,
    required this.isCorrect,
    required this.showCorrectAnswer,
  });

  @override
  State<MCQWidget> createState() => _MCQWidgetState();
}

class _MCQWidgetState extends State<MCQWidget> {
  String? selectedAnswer;
  List<String> shuffledOptions = [];

  @override
  void initState() {
    super.initState();
    _initializeOptions();
  }

  @override
  void didUpdateWidget(MCQWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selection when question changes
    if (oldWidget.question.id != widget.question.id) {
      setState(() {
        selectedAnswer = null;
      });
      _initializeOptions();
    }
  }

  void _initializeOptions() {
    if (widget.question.options != null) {
      shuffledOptions = List<String>.from(widget.question.options!);
      shuffledOptions.shuffle(Random());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.question.images.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.question.images.first,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),
            ),
          
          // MCQ Options
          ...shuffledOptions.map((option) {
            final isSelected = selectedAnswer == option;
            final isCorrectOption = widget.question.correctAnswer == option;
            
            Color optionColor = Colors.grey.shade100;
            Color textColor = Colors.black;
            Color borderColor = Colors.grey.shade300;
            
            if (widget.isAnswered) {
              if (isSelected) {
                if (widget.isCorrect) {
                  optionColor = Colors.green.shade100;
                  textColor = Colors.green.shade800;
                  borderColor = Colors.green;
                } else {
                  optionColor = Colors.red.shade100;
                  textColor = Colors.red.shade800;
                  borderColor = Colors.red;
                }
              }
              if (widget.showCorrectAnswer && isCorrectOption) {
                optionColor = Colors.green.shade100;
                textColor = Colors.green.shade800;
                borderColor = Colors.green;
              }
            } else if (isSelected) {
              borderColor = Colors.blue;
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: optionColor,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.isAnswered ? null : () {
                    setState(() {
                      selectedAnswer = option;
                    });
                    widget.onAnswer(option);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Fixed Fill-up Widget with proper controller reset
class FillUpWidget extends StatefulWidget {
  final QuizQuestion question;
  final Function(dynamic) onAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final bool showCorrectAnswer;

  const FillUpWidget({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.isAnswered,
    required this.isCorrect,
    required this.showCorrectAnswer,
  });

  @override
  State<FillUpWidget> createState() => _FillUpWidgetState();
}

class _FillUpWidgetState extends State<FillUpWidget> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(FillUpWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset controller when question changes
    if (oldWidget.question.id != widget.question.id) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.question.images.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.question.images.first,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),
            ),
          
          // Fill-up input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: widget.isAnswered 
                  ? (widget.isCorrect ? Colors.green.shade50 : Colors.red.shade50)
                  : Colors.white,
            ),
            child: TextField(
              controller: _controller,
              enabled: !widget.isAnswered,
              decoration: const InputDecoration(
                hintText: 'Type your answer here...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (widget.showCorrectAnswer)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Correct Answer: ${widget.question.correctAnswer}',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          if (!widget.isAnswered)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    widget.onAnswer(_controller.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Submit Answer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Updated Ordering Widget with image display and proper state reset
class OrderingWidget extends StatefulWidget {
  final QuizQuestion question;
  final Function(dynamic) onAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final bool showCorrectAnswer;

  const OrderingWidget({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.isAnswered,
    required this.isCorrect,
    required this.showCorrectAnswer,
  });

  @override
  State<OrderingWidget> createState() => _OrderingWidgetState();
}

class _OrderingWidgetState extends State<OrderingWidget> {
  List<String> orderedItems = [];
  List<String> availableItems = [];

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  @override
  void didUpdateWidget(OrderingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset items when question changes
    if (oldWidget.question.id != widget.question.id) {
      _initializeItems();
    }
  }

  void _initializeItems() {
    final correctOrder = List<String>.from(widget.question.correctAnswer);
    availableItems = List<String>.from(correctOrder);
    availableItems.shuffle(Random());
    orderedItems = [];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // FIXED: Display image if available from database
          if (widget.question.images.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.question.images.first,
                  fit: BoxFit.contain,
                  height: 200,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          const Text(
            'Arrange in correct order:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: orderedItems.isEmpty
                ? const Text(
                    'Tap items below to add them here',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...orderedItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        String item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(item)),
                              if (!widget.isAnswered)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      orderedItems.remove(item);
                                      availableItems.add(item);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Available items:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableItems.map((item) {
              return ActionChip(
                label: Text(item),
                onPressed: widget.isAnswered ? null : () {
                  setState(() {
                    availableItems.remove(item);
                    orderedItems.add(item);
                  });
                },
                backgroundColor: Colors.blue.shade100,
                labelStyle: TextStyle(color: Colors.blue.shade800),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          
          if (widget.showCorrectAnswer)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Correct Order:',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...((widget.question.correctAnswer as List).asMap().entries.map((entry) {
                    return Text(
                      '${entry.key + 1}. ${entry.value}',
                      style: TextStyle(color: Colors.green.shade800),
                    );
                  })),
                ],
              ),
            ),
          
          if (!widget.isAnswered && orderedItems.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () => widget.onAnswer(orderedItems),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Submit Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Enhanced Drag & Drop Widget with better state management
class DragDropWidget extends StatefulWidget {
  final QuizQuestion question;
  final Function(dynamic) onAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final bool showCorrectAnswer;

  const DragDropWidget({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.isAnswered,
    required this.isCorrect,
    required this.showCorrectAnswer,
  });

  @override
  State<DragDropWidget> createState() => _DragDropWidgetState();
}

class _DragDropWidgetState extends State<DragDropWidget> {
  String? droppedTarget;

  @override
  void didUpdateWidget(DragDropWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset dropped target when question changes
    if (oldWidget.question.id != widget.question.id) {
      setState(() {
        droppedTarget = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final answerData = widget.question.correctAnswer as Map<String, dynamic>;
    final draggableUrl = answerData['draggable'] as String;
    final options = List<String>.from(answerData['options']);
    final correctTarget = answerData['correctTarget'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Drag the image to the correct target:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Center(
            child: Draggable<String>(
              data: 'draggable_image',
              feedback: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Image.network(draggableUrl, fit: BoxFit.cover),
              ),
              childWhenDragging: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade300,
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    draggableUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isDropped = droppedTarget == option;
              
              Color backgroundColor = Colors.grey.shade100;
              Color textColor = Colors.black;
              
              if (widget.isAnswered) {
                if (isDropped) {
                  backgroundColor = widget.isCorrect ? Colors.green.shade100 : Colors.red.shade100;
                  textColor = widget.isCorrect ? Colors.green.shade800 : Colors.red.shade800;
                }
                if (widget.showCorrectAnswer && option == correctTarget) {
                  backgroundColor = Colors.green.shade100;
                  textColor = Colors.green.shade800;
                }
              }

              return DragTarget<String>(
                onAccept: (data) {
                  setState(() {
                    droppedTarget = option;
                  });
                  widget.onAnswer(option);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: candidateData.isNotEmpty 
                            ? Colors.blue 
                            : Colors.grey.shade300,
                        width: candidateData.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (widget.showCorrectAnswer)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Correct Answer: $correctTarget',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// FIXED: Updated Tap on Image Widget with accurate Region-based detection
class TapImageWidget extends StatefulWidget {
  final QuizQuestion question;
  final Function(dynamic) onAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final bool showCorrectAnswer;

  const TapImageWidget({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.isAnswered,
    required this.isCorrect,
    required this.showCorrectAnswer,
  });

  @override
  State<TapImageWidget> createState() => _TapImageWidgetState();
}

class _TapImageWidgetState extends State<TapImageWidget> {
  Offset? tappedPosition;
  String feedback = '';
  String selectedRegion = 'None';
  GlobalKey imageKey = GlobalKey();
  bool _hasTapped = false;

  @override
  void didUpdateWidget(TapImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      setState(() {
        tappedPosition = null;
        feedback = '';
        selectedRegion = 'None';
        _hasTapped = false;
      });
    }
  }

  void _onTap(TapDownDetails details) {
    if (widget.isAnswered || _hasTapped) return;

    final RenderBox? box = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset position = box.globalToLocal(details.globalPosition);
    final Size imageSize = box.size;
    
    // Convert tap position to normalized coordinates
    final normalizedX = position.dx / imageSize.width;
    final normalizedY = position.dy / imageSize.height;
    
    print('Tapped at pixels: ${position.dx}, ${position.dy}');
    print('Image size: ${imageSize.width} x ${imageSize.height}');
    print('Normalized tap: ${normalizedX.toStringAsFixed(3)}, ${normalizedY.toStringAsFixed(3)}');

    // Get stored normalized coordinates
    final coords = widget.question.correctCoordinates;
    bool isCorrectTap = false;
    
    if (coords != null) {
      final rectX = coords['x']!;
      final rectY = coords['y']!;
      final rectW = coords['w']!;
      final rectH = coords['h']!;
      
      print('Stored normalized rect: x=$rectX, y=$rectY, w=$rectW, h=$rectH');
      
      // Check if normalized tap coordinates fall within normalized rectangle
      if (normalizedX >= rectX && 
          normalizedX <= rectX + rectW && 
          normalizedY >= rectY && 
          normalizedY <= rectY + rectH) {
        isCorrectTap = true;
      }
    }

    setState(() {
      tappedPosition = position;
      selectedRegion = isCorrectTap ? 'CorrectArea' : 'WrongArea';
      feedback = isCorrectTap ? '✅ Correct!' : '❌ Incorrect.';
      _hasTapped = true;
    });

    widget.onAnswer({
      'x': position.dx,
      'y': position.dy,
      'normalizedX': normalizedX,
      'normalizedY': normalizedY,
      'region': selectedRegion,
      'correct': isCorrectTap,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap on the correct area of the image:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          
          if (widget.question.images.isNotEmpty)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTapDown: _onTap,
                    child: Stack(
                      key: imageKey,
                      children: [
                        Image.network(
                          widget.question.images.first,
                          fit: BoxFit.contain,
                          alignment: Alignment.topLeft,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 50),
                              ),
                            );
                          },
                        ),
                        
                        // Show red X for wrong tap
                        if (tappedPosition != null && widget.isAnswered && !widget.isCorrect)
                          Positioned(
                            left: tappedPosition!.dx - 15,
                            top: tappedPosition!.dy - 15,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.red, width: 2),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        
                        // Show correct area when answer is wrong
                        if (widget.showCorrectAnswer && !widget.isCorrect && widget.question.correctCoordinates != null)
                          Builder(
                            builder: (context) {
                              final RenderBox? box = imageKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box == null) return Container();
                              
                              final imageSize = box.size;
                              final coords = widget.question.correctCoordinates!;
                              
                              // Convert normalized coordinates to pixel coordinates
                              final pixelX = coords['x']! * imageSize.width;
                              final pixelY = coords['y']! * imageSize.height;
                              final pixelW = coords['w']! * imageSize.width;
                              final pixelH = coords['h']! * imageSize.height;
                              
                              return Positioned(
                                left: pixelX,
                                top: pixelY,
                                child: Container(
                                  width: pixelW,
                                  height: pixelH,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green, width: 3),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          if (widget.isAnswered)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.isCorrect 
                    ? 'Correct!' 
                    : 'Incorrect. The correct area is highlighted.',
                style: TextStyle(
                  color: widget.isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


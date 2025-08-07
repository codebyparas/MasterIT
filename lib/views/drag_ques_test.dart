import 'package:flutter/material.dart';

class DragQuesView extends StatefulWidget {
  @override
  _DragQuesViewState createState() => _DragQuesViewState();
}

class _DragQuesViewState extends State<DragQuesView> {
  String? droppedInBox; // which box the flag was dropped into
  final String correctCountry = 'India';
  bool flagPlacedCorrectly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Drag the Flag to the Correct Country')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Drag the 🇮🇳 flag to the correct country box',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),

            // Draggable Flag (only show if not placed correctly)
            if (!flagPlacedCorrectly)
              Draggable<String>(
                data: 'India',
                feedback: Image.asset('assets/icons/world_map.jpg', width: 60),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: Image.asset('assets/icons/world_map.jpg', width: 60),
                ),
                child: Image.asset('assets/icons/world_map.jpg', width: 60),
              ),

            SizedBox(height: 80),

            // Drop Targets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDropTarget('India'),
                _buildDropTarget('USA'),
                _buildDropTarget('Brazil'),
              ],
            ),

            SizedBox(height: 40),

            // Feedback Message
            if (droppedInBox != null)
              Text(
                flagPlacedCorrectly
                    ? '✅ Correct!'
                    : '❌ Wrong. That’s $droppedInBox.',
                style: TextStyle(
                  fontSize: 20,
                  color: flagPlacedCorrectly ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropTarget(String country) {
    return DragTarget<String>(
      onAccept: (receivedCountry) {
        setState(() {
          droppedInBox = country;
          flagPlacedCorrectly = (country == correctCountry);
        });
      },
      builder: (context, candidateData, rejectedData) {
        bool isHighlighted = candidateData.isNotEmpty;

        return Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.yellow[200] : Colors.grey[300],
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(country, style: TextStyle(fontSize: 16)),
              if (flagPlacedCorrectly && country == correctCountry)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.asset('assets/icons/world_map.jpg', width: 40),
                ),
            ],
          ),
        );
      },
    );
  }
}

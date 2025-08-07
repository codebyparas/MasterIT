import 'package:flutter/material.dart';

class Region {
  final String name;
  final Rect bounds;

  Region({required this.name, required this.bounds});
}

class MapQuesView extends StatefulWidget {
  @override
  _MapQuesViewState createState() => _MapQuesViewState();
}

class _MapQuesViewState extends State<MapQuesView> {
  Offset? tapPosition;
  String feedback = '';

  // Define regions with pixel bounds matching original image size
  final List<Region> regions = [
    Region(name: 'India', bounds: Rect.fromLTWH(300, 200, 100, 100)),
    // Region(name: 'USA', bounds: Rect.fromLTWH(50, 100, 100, 80)),
    Region(name: 'Australia', bounds: Rect.fromLTWH(600, 400, 120, 100)),
    Region(name: 'Nepal', bounds: Rect.fromLTWH(148, 92, 90, 59)),
  ];

  final String correctAnswer = 'India';

  void _onTap(TapDownDetails details) {
    final Offset position = details.localPosition;
    String selectedRegion = 'None';
    print('Tapped at: ${position.dx}, ${position.dy}');

    for (Region region in regions) {
      if (region.bounds.contains(position)) {
        selectedRegion = region.name;
        break;
      }
    }

    setState(() {
      tapPosition = position;
      feedback = (selectedRegion == correctAnswer)
          ? '✅ Correct! You tapped on $selectedRegion.'
          : '❌ Wrong. You tapped on $selectedRegion.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map Quiz')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTapDown: _onTap,
                child: SizedBox(
                  width: 700, // match image size
                  height: 834,
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/icons/world_map.jpg',
                        fit: BoxFit.none, // <-- Prevent scaling
                        alignment:
                            Alignment.topLeft, // <-- Match top-left origin
                      ),
                      if (tapPosition != null)
                        Positioned(
                          left: tapPosition!.dx - 5,
                          top: tapPosition!.dy - 5,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              feedback,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// rectangle_selector.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// RectangleSelectorPage
/// - Presents the image (fit = contain) and lets the user drag to draw a rectangle.
/// - Returns a Map<String, double> with keys: 'x','y','width','height' (normalized 0..1
///   relative to the image intrinsic size).
class RectangleSelectorPage extends StatefulWidget {
  final String imagePath;
  const RectangleSelectorPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<RectangleSelectorPage> createState() => _RectangleSelectorPageState();
}

class _RectangleSelectorPageState extends State<RectangleSelectorPage> {
  // Intrinsic image size (original pixels)
  int? _imageIntrinsicWidth;
  int? _imageIntrinsicHeight;
  bool _loadingImageInfo = true;
  String? _error;

  // Gesture points in the displayed image coordinate space (pixels)
  Offset? _startInImage; // local to displayed-image top-left
  Offset? _currentInImage;
  Rect? _rectInImage; // in displayed-image pixels

  // Cached computed layout values for the current layout pass
  Size? _lastConstraintsSize;
  double _displayedImageWidth = 0;
  double _displayedImageHeight = 0;
  double _displayedImageOffsetLeft = 0;
  double _displayedImageOffsetTop = 0;

  @override
  void initState() {
    super.initState();
    _loadIntrinsicImageSize();
  }

  Future<void> _loadIntrinsicImageSize() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      setState(() {
        _imageIntrinsicWidth = image.width;
        _imageIntrinsicHeight = image.height;
        _loadingImageInfo = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load image info: $e';
        _loadingImageInfo = false;
      });
    }
  }

  // Compute displayed image size & offset given the available box
  void _computeDisplayedImageLayout(BoxConstraints constraints) {
    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;

    final iw = _imageIntrinsicWidth?.toDouble() ?? 1.0;
    final ih = _imageIntrinsicHeight?.toDouble() ?? 1.0;
    final imgRatio = iw / ih;

    double dw = maxW;
    double dh = dw / imgRatio;

    if (dh > maxH) {
      dh = maxH;
      dw = dh * imgRatio;
    }

    _displayedImageWidth = dw;
    _displayedImageHeight = dh;
    _displayedImageOffsetLeft = (maxW - dw) / 2.0;
    _displayedImageOffsetTop = (maxH - dh) / 2.0;
  }

  // Convert global position to position inside displayed image (clamped)
  Offset _globalToImageLocal(Offset global, RenderBox box) {
    final local = box.globalToLocal(global);
    final imgLocalX = (local.dx - _displayedImageOffsetLeft).clamp(0.0, _displayedImageWidth);
    final imgLocalY = (local.dy - _displayedImageOffsetTop).clamp(0.0, _displayedImageHeight);
    return Offset(imgLocalX, imgLocalY);
  }

  // Build rect from two image-local points
  Rect _rectFromImagePoints(Offset a, Offset b) {
    final left = a.dx < b.dx ? a.dx : b.dx;
    final top = a.dy < b.dy ? a.dy : b.dy;
    final right = a.dx > b.dx ? a.dx : b.dx;
    final bottom = a.dy > b.dy ? a.dy : b.dy;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  // Save: return normalized rectangle relative to intrinsic image (0..1)
  void _onSave() {
    if (_rectInImage == null || _imageIntrinsicWidth == null || _imageIntrinsicHeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please draw a rectangle first')));
      return;
    }

    // The rectangle coordinates are in displayed-image pixels. To normalize relative to the intrinsic image,
    // we need to map from displayed-image pixel space to intrinsic pixel space.
    final scaleX = (_imageIntrinsicWidth! / _displayedImageWidth);
    final scaleY = (_imageIntrinsicHeight! / _displayedImageHeight);

    // Convert displayed rect to intrinsic-pixel rect
    final intrinsicLeft = (_rectInImage!.left * scaleX).clamp(0.0, _imageIntrinsicWidth!.toDouble());
    final intrinsicTop = (_rectInImage!.top * scaleY).clamp(0.0, _imageIntrinsicHeight!.toDouble());
    final intrinsicW = (_rectInImage!.width * scaleX).clamp(0.0, _imageIntrinsicWidth!.toDouble());
    final intrinsicH = (_rectInImage!.height * scaleY).clamp(0.0, _imageIntrinsicHeight!.toDouble());

    // Normalize to 0..1 (relative to intrinsic size)
    final nx = (intrinsicLeft / _imageIntrinsicWidth!).clamp(0.0, 1.0);
    final ny = (intrinsicTop / _imageIntrinsicHeight!).clamp(0.0, 1.0);
    final nw = (intrinsicW / _imageIntrinsicWidth!).clamp(0.0, 1.0);
    final nh = (intrinsicH / _imageIntrinsicHeight!).clamp(0.0, 1.0);

    Navigator.of(context).pop<Map<String, double>>({
      'x': nx,
      'y': ny,
      'width': nw,
      'height': nh,
    });
  }

  void _onClear() {
    setState(() {
      _startInImage = null;
      _currentInImage = null;
      _rectInImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingImageInfo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Rectangle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Rectangle')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Rectangle'),
        actions: [
          TextButton(
            onPressed: _rectInImage == null ? null : _onSave,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // compute displayed image layout for this pass
          _computeDisplayedImageLayout(constraints);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              final box = context.findRenderObject() as RenderBox;
              final p = _globalToImageLocal(details.globalPosition, box);
              setState(() {
                _startInImage = p;
                _currentInImage = p;
                _rectInImage = null;
              });
            },
            onPanUpdate: (details) {
              if (_startInImage == null) return;
              final box = context.findRenderObject() as RenderBox;
              final p = _globalToImageLocal(details.globalPosition, box);
              setState(() {
                _currentInImage = p;
                _rectInImage = _rectFromImagePoints(_startInImage!, _currentInImage!);
              });
            },
            onPanEnd: (details) {
              if (_startInImage == null || _currentInImage == null) return;
              setState(() {
                _rectInImage = _rectFromImagePoints(_startInImage!, _currentInImage!);
                _startInImage = null;
                _currentInImage = null;
              });
            },
            child: Container(
              color: Colors.black12,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  // centered image box
                  Positioned(
                    left: _displayedImageOffsetLeft,
                    top: _displayedImageOffsetTop,
                    width: _displayedImageWidth,
                    height: _displayedImageHeight,
                    child: ClipRect(
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  // overlay rectangle (if any), positioned relative to image display region
                  if (_rectInImage != null)
                    Positioned(
                      left: _displayedImageOffsetLeft + _rectInImage!.left,
                      top: _displayedImageOffsetTop + _rectInImage!.top,
                      width: _rectInImage!.width,
                      height: _rectInImage!.height,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent, width: 2.0),
                            color: Colors.redAccent.withOpacity(0.12),
                          ),
                        ),
                      ),
                    ),

                  // instructions & controls
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _rectInImage == null ? 'Drag to draw a rectangle' : 'Rectangle ready — tap Save',
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: _rectInImage == null ? null : _onClear,
                          child: const Text('Clear', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadPhotoView extends StatefulWidget {
  const UploadPhotoView({super.key});

  @override
  _UploadPhotoViewState createState() => _UploadPhotoViewState();
}

class _UploadPhotoViewState extends State<UploadPhotoView> {
  File? _image;
  bool _isLoading = false;
  List<String> _imageUrls = [];

  final supabase = Supabase.instance.client;
  final bucketName = 'photos'; // make sure this matches your bucket

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from(bucketName).upload(fileName, _image!);

      // Get public URL
      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload successful!")));

      setState(() {
        _image = null;
        _imageUrls.insert(0, publicUrl); // add new image at the top
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchImages() async {
    try {
      final response = await supabase.storage.from(bucketName).list();
      final urls = response.map((file) {
        return supabase.storage.from(bucketName).getPublicUrl(file.name);
      }).toList();

      setState(() {
        _imageUrls = urls;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch images: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload & View Photos")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Image picker + preview
            _image != null
                ? Image.file(_image!, height: 200)
                : const Icon(Icons.image, size: 100, color: Colors.grey),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Choose Photo"),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _uploadImage,
              icon: const Icon(Icons.cloud_upload),
              label: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    )
                  : const Text("Upload"),
            ),

            const Divider(height: 40),

            // Gallery of uploaded images
            const Text(
              "Uploaded Images",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _imageUrls.isEmpty
                ? const Text("No images uploaded yet")
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: _imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        _imageUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

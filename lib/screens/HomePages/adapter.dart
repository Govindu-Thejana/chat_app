import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class UploadImagePage extends StatefulWidget {
  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  File? _imageFile;
  String _imageUrl = "";

  // Cloudinary API details
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/dixuwjo5z/image/upload";
  final String apiKey = "495819161826559";
  final String apiSecret = "4MiQfBEDWFk5KgBBpTZoYafoy7w";
  final String uploadPreset = "chatjet";

  final Logger logger = Logger();

  // Pick an image using Image Picker
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      logger.i("Image selected: ${_imageFile!.path}");
    } else {
      logger.w("No image selected.");
    }
  }

  // Upload image to Cloudinary
  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      logger.w("No image to upload.");
      return;
    }

    try {
      final request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files
            .add(await http.MultipartFile.fromPath("file", _imageFile!.path));

      logger.i("Uploading image: ${_imageFile!.path}");

      final response = await request.send();

      // Log raw response
      logger.i("Response status: ${response.statusCode}");
      logger.i("Response headers: ${response.headers}");

      final responseData = await response.stream.bytesToString();

      // Log response data
      logger.i("Response data: $responseData");

      final responseJson = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _imageUrl = responseJson["secure_url"];
        });
        logger.i("Upload successful, image URL: $_imageUrl");
      } else {
        logger.e("Upload failed: ${responseJson['error']}");
      }
    } catch (e) {
      logger.e("Error during upload: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Image to Cloudinary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _imageFile == null
                ? Text("No image selected.")
                : Image.file(_imageFile!, height: 200, width: 200),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick Image from Gallery"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text("Upload Image to Cloudinary"),
            ),
            SizedBox(height: 20),
            _imageUrl.isNotEmpty
                ? Column(
                    children: [
                      Text("Image URL:"),
                      SelectableText(_imageUrl),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
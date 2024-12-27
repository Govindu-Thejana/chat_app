import 'dart:io';
import 'dart:convert';
import 'package:chat_app/controlers/status_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:chat_app/models/status_model.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class StatusProvider with ChangeNotifier {
  final StatusController _statusController = StatusController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<StatusModel> _statuses = [];
  StatusModel? _myStatus;
  String _statusImageUrl = '';
  XFile? _pickedFile;
  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  List<StatusModel> get statuses => _statuses;
  StatusModel? get mystatus => _myStatus;
  String get statusImageUrl => _statusImageUrl;

  set statusImageUrl(String url) {
    _statusImageUrl = url;
    notifyListeners();
  }

  /// Cloudinary upload function
  Future<String> uploadImageToCloudinary(File imageFile) async {
    try {
      const String cloudinaryUrl =
          "https://api.cloudinary.com/v1_1/dixuwjo5z/image/upload";
      const String uploadPreset = "chatjet";

      final request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['secure_url']; // Cloudinary URL
      } else {
        throw Exception("Failed to upload image: ${response.reasonPhrase}");
      }
    } catch (e) {
      _logger.e("Error uploading to Cloudinary: $e");
      rethrow;
    }
  }

  /// Select, crop, and upload a status image
  Future<void> selectStatusImage(BuildContext context) async {
    try {
      _pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (_pickedFile != null) {
        _logger.i('Status image selected: ${_pickedFile?.path}');

        // Crop the image
        File? croppedImg = await _cropImage(context, File(_pickedFile!.path));
        if (croppedImg != null) {
          _logger.i("Status image cropped: ${croppedImg.path}");

          // Upload the image to Cloudinary
          final String cloudinaryUrl =
              await uploadImageToCloudinary(croppedImg);

          _logger.i("Status image uploaded to Cloudinary: $cloudinaryUrl");

          // Save the URL to Firestore
          final String statusId = _uuid.v4();
          final statusData = {
            'statusId': statusId,
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'statusImageUrls': [cloudinaryUrl],
            'timestamp': DateTime.now().toIso8601String(),
          };

          await _firestore.collection('status').doc(statusId).set(statusData);
          _logger.i("Status saved to Firestore successfully.");

          _statusImageUrl = cloudinaryUrl;
          notifyListeners();
        } else {
          _logger.i("Image cropping was cancelled.");
        }
      } else {
        _logger.i("Image selection was cancelled.");
      }
    } catch (e) {
      _logger.e("Error selecting or uploading status image: $e");
    }
  }

  /// Delete a status item by index
  Future<void> deleteStatusItem(int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot statusSnapshot = await _firestore
            .collection('status')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (statusSnapshot.docs.isNotEmpty) {
          DocumentSnapshot existingStatusDoc = statusSnapshot.docs.first;
          StatusModel existingStatus = StatusModel.fromMap(
              existingStatusDoc.data() as Map<String, dynamic>);

          List<String> existingImageUrls =
              List<String>.from(existingStatus.statusImageUrls ?? []);
          List<String> existingTexts =
              List<String>.from(existingStatus.statusText ?? []);

          // Remove the image URL and text at the specified index
          if (index >= 0 && index < existingImageUrls.length) {
            existingImageUrls.removeAt(index);
          }
          if (index >= 0 && index < existingTexts.length) {
            existingTexts.removeAt(index);
          }

          // Update the status document
          await _firestore
              .collection('status')
              .doc(existingStatus.statusId)
              .update({
            'statusImageUrls': existingImageUrls,
            'statusText': existingTexts,
            'timestamp': DateTime.now().toIso8601String(),
          });

          _logger.i(
              'Status item deleted successfully: ${existingStatus.statusId}');
          fetchStatuses();
        } else {
          _logger.i('No status found for the user.');
        }
      } catch (e) {
        _logger.e('Failed to delete status item: $e');
      }
    } else {
      _logger.i('No user is signed in.');
    }
  }

  /// Crop an image
  Future<File?> _cropImage(BuildContext context, File file) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        maxHeight: 512,
        maxWidth: 512,
        compressQuality: 60,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Status Image',
              toolbarColor: Colors.purple, // Replace with any desired color
            toolbarWidgetColor: Colors.white,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Status Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
            ],
          ),
          WebUiSettings(context: context),
        ],
      );

      if (croppedFile != null) {
        _logger.i('Status image cropped: ${croppedFile.path}');
        return File(croppedFile.path);
      } else {
        _logger.i('Status image cropping was cancelled or failed.');
        return null;
      }
    } catch (e) {
      _logger.e('Error cropping status image: $e');
      return null;
    }
  }

  /// Fetch statuses
  Future<void> fetchStatuses() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.i('No user is signed in.');
        return;
      }

      final allStatuses = await _statusController.getStatuses();
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 24));

      List<StatusModel> validStatuses = allStatuses.where((status) {
        final statusTimestamp = DateTime.parse(status.timestamp.toString());
        return statusTimestamp.isAfter(cutoff);
      }).toList();

      _statuses = validStatuses.where((status) => status.userId != user.uid).toList();
      _myStatus =
          validStatuses.firstWhereOrNull((status) => status.userId == user.uid);

      notifyListeners();
    } catch (e) {
      _logger.e('Failed to fetch statuses: $e');
    }
  }
}

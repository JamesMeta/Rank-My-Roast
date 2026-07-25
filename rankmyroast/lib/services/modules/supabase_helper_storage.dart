import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelperStorage {
  static final _client = Supabase.instance.client;
  static final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromCamera() async {
    // 1. Specifically check for Camera permission
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      // 2. Launch the Camera UI
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera, // Hard-coded to camera
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(
            ratioX: 4,
            ratioY: 3,
          ), // Forces a Square
          compressQuality: 90,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: Colors.green,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Prevents user from changing the ratio
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              aspectRatioLockEnabled: true,
              resetButtonHidden: true,
            ),
          ],
        );

        return croppedFile != null ? File(croppedFile.path) : null;
      }
    } else if (status.isPermanentlyDenied) {
      // If the user denied it previously, send them to settings
      await openAppSettings();
    }

    return null;
  }

  Future<File?> pickImageFromGallery() async {
    // 1. Determine Permission (Gallery specific)
    // Note: On Android 13+, Permission.photos is often preferred over Permission.storage
    Permission permission = Permission.photos;

    // 2. Request/Check Permission
    PermissionStatus status = await permission.request();

    if (status.isGranted || status.isLimited) {
      // Added isLimited for iOS 14+ support
      // 3. Pick the Image from the Gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // Switched to gallery
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
          compressQuality: 90,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: Colors.green,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Prevents user from changing the ratio
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              aspectRatioLockEnabled: true,
              resetButtonHidden: true,
            ),
          ],
        );

        return croppedFile != null ? File(croppedFile.path) : null;
      }
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return null;
  }

  Future<String?> uploadFileToBucket({
    required String bucketName,
    required File file,
    required String fileName,
  }) async {
    final supabase = Supabase.instance.client;

    // Construct the full path: "folder/filename.ext"
    final String path = fileName;

    try {
      await supabase.storage
          .from(bucketName)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      print('Upload successful to $bucketName/$path');
      return path;
    } on StorageException catch (error) {
      print('Storage Error: ${error.message}');
      return null;
    } catch (error) {
      print('Unexpected Error: $error');
      return null;
    }
  }

  Future<String?> uploadFileToFolder({
    required String bucketName,
    required String folderName,
    required File file,
    required String fileName,
  }) async {
    final supabase = Supabase.instance.client;

    // Construct the full path: "folder/filename.ext"
    final String path = '$folderName/$fileName';

    try {
      await supabase.storage
          .from(bucketName)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      print('Upload successful to $bucketName/$path');
      return path;
    } on StorageException catch (error) {
      print('Storage Error: ${error.message}');
      return null;
    } catch (error) {
      print('Unexpected Error: $error');
      return null;
    }
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

/// Service for handling image operations: picking, compressing, and storing
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Pick image from gallery
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return await _processAndSaveImage(pickedFile.path);
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return await _processAndSaveImage(pickedFile.path);
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Process and save image to app directory
  Future<String?> _processAndSaveImage(String imagePath) async {
    try {
      // Read the original image
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Compress image if too large
      img.Image processedImage = originalImage;

      // Resize if width > 1920 or height > 1080
      if (originalImage.width > 1920 || originalImage.height > 1080) {
        processedImage = img.copyResize(
          originalImage,
          width: originalImage.width > 1920 ? 1920 : null,
          height: originalImage.height > 1080 ? 1080 : null,
        );
      }

      // Encode to JPEG with compression
      final List<int> compressedBytes =
          img.encodeJpg(processedImage, quality: 85);

      // Get app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/note_images');

      // Create directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate unique filename
      final String filename = '${_uuid.v4()}.jpg';
      final String savedPath = '${imagesDir.path}/$filename';

      // Save compressed image
      final File savedFile = File(savedPath);
      await savedFile.writeAsBytes(compressedBytes);

      return savedPath;
    } catch (e) {
      print('Error processing and saving image: $e');
      return null;
    }
  }

  /// Delete image file
  Future<bool> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Get image file size in KB
  Future<int> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        final int bytes = await imageFile.length();
        return (bytes / 1024).round(); // Convert to KB
      }
      return 0;
    } catch (e) {
      print('Error getting image size: $e');
      return 0;
    }
  }

  /// Check if image file exists
  Future<bool> imageExists(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Clean up unused images (images not referenced in any note)
  Future<int> cleanupUnusedImages(Set<String> usedImagePaths) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/note_images');

      if (!await imagesDir.exists()) return 0;

      int deletedCount = 0;
      final List<FileSystemEntity> files = await imagesDir.list().toList();

      for (var file in files) {
        if (file is File) {
          if (!usedImagePaths.contains(file.path)) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      print('Error cleaning up unused images: $e');
      return 0;
    }
  }
}

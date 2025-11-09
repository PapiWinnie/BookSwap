import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// fixed warning: use debugPrint instead of print for production-safe logging
import 'package:flutter/foundation.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  // Load from .env file - SECURE!
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // Pick image from gallery OR camera
  Future<File?> pickImage({bool fromGallery = true}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  // Upload book cover image to Cloudinary using SIGNED upload (no preset needed)
  Future<String?> uploadBookCover(File imageFile, String userId) async {
    try {
      // Validate credentials
      if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
        throw Exception(
          'Cloudinary credentials not configured. Check your .env file.',
        );
      }

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // Generate timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final folder = 'book_covers/$userId';

      // Generate signature for signed upload
      final signature = _generateUploadSignature(folder, timestamp.toString());

      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add signed upload parameters
      request.fields['folder'] = folder;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['api_key'] = apiKey;
      request.fields['signature'] = signature;

      // fixed warning: replaced print with debugPrint
      debugPrint('📤 Uploading image to Cloudinary (signed)...');

      // Send request
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        final imageUrl = jsonResponse['secure_url'] as String;
        // fixed warning: replaced print with debugPrint
        debugPrint('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        // fixed warning: replaced print with debugPrint
        debugPrint('❌ Upload failed: ${response.statusCode} - $responseString');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }

  // Generate signature for upload (signed upload)
  String _generateUploadSignature(String folder, String timestamp) {
    // Parameters must be in alphabetical order
    final params = 'folder=$folder&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(params);
    final hash = sha1.convert(bytes);
    return hash.toString();
  }

  // Delete image from Cloudinary
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Validate credentials
      if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
        // fixed warning: replaced print with debugPrint
        debugPrint('⚠️ Cloudinary credentials not configured for deletion');
        return;
      }

      // Extract public_id from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the public_id (everything after 'upload/')
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        // fixed warning: replaced print with debugPrint
        debugPrint('⚠️ Could not extract public_id from URL');
        return;
      }

      // Get public_id (path after upload, without file extension)
      final publicIdParts = pathSegments.sublist(uploadIndex + 2);
      final publicId = publicIdParts
          .join('/')
          .replaceAll(RegExp(r'\.[^.]+$'), '');

      // Generate signature for authenticated request
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateDeleteSignature(
        publicId,
        timestamp.toString(),
      );

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
      );

      // fixed warning: replaced print with debugPrint
      debugPrint('🗑️ Deleting image from Cloudinary...');

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'signature': signature,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['result'] == 'ok') {
          // fixed warning: replaced print with debugPrint
          debugPrint('✅ Image deleted successfully: $publicId');
        } else {
          // fixed warning: replaced print with debugPrint
          debugPrint('⚠️ Delete response: ${response.body}');
        }
      } else {
        // fixed warning: replaced print with debugPrint
        debugPrint(
          '⚠️ Delete failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // fixed warning: replaced print with debugPrint
      debugPrint('⚠️ Delete error: $e');
      // Don't throw - deletion errors shouldn't break the app
    }
  }

  // Generate signature for deletion
  String _generateDeleteSignature(String publicId, String timestamp) {
    final params = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(params);
    final hash = sha1.convert(bytes);
    return hash.toString();
  }
}

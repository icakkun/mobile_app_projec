import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CloudinaryService {
  // ⚠️ REPLACE WITH YOUR CLOUDINARY CREDENTIALS
  static const String cloudName = 'dwrptvops';
  static const String uploadPreset = 'trip_mint_receipts';

  /// Upload image to Cloudinary (WEB COMPATIBLE)
  /// Returns the secure URL of the uploaded image
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url);

      // Add upload preset
      request.fields['upload_preset'] = uploadPreset;

      // Add folder (optional, for organization)
      request.fields['folder'] = 'receipts';

      // Add timestamp to filename for uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      request.fields['public_id'] = 'receipt_$timestamp';

      // ✅ WEB COMPATIBLE: Read file as bytes and use fromBytes
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      );

      request.files.add(multipartFile);

      print('📤 Uploading image to Cloudinary...');

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        final secureUrl = jsonResponse['secure_url'] as String;

        print('✅ Upload successful: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('Response: $responseString');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Delete image from Cloudinary (optional)
  /// Requires API key and secret, so should be done from backend
  /// For now, we'll just remove the reference
  static Future<bool> deleteImage(String imageUrl) async {
    // Note: Actual deletion requires API secret
    // For client-side, we just remove the reference
    // Images will stay in Cloudinary but won't be referenced
    print('🗑️ Removing image reference: $imageUrl');
    return true;
  }

  /// Get optimized thumbnail URL
  /// Cloudinary allows URL transformations
  static String getOptimizedUrl(
    String originalUrl, {
    int width = 400,
    int height = 400,
    String quality = 'auto',
  }) {
    // Example: transforms/w_400,h_400,c_fill,q_auto
    if (originalUrl.contains('cloudinary.com')) {
      final parts = originalUrl.split('/upload/');
      if (parts.length == 2) {
        return '${parts[0]}/upload/w_$width,h_$height,c_fill,q_$quality/${parts[1]}';
      }
    }
    return originalUrl;
  }
}

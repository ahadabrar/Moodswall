import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:moodwalls/features/wallpaper/download_result.dart';
export 'download_result.dart';

Future<DownloadResult> downloadImage(String imageUrl, String filename) async {
  try {
    // 1. Check/Request permission
    final hasPermission = await Gal.hasAccess();
    if (!hasPermission) {
      await Gal.requestAccess();
    }

    // 2. Download the image
    final response = await http.get(Uri.parse(imageUrl)).timeout(
      const Duration(seconds: 20),
    );

    if (response.statusCode == 200) {
      // 3. Save to gallery
      await Gal.putImageBytes(response.bodyBytes, name: filename);
      return DownloadResult(
        success: true,
        message: 'Wallpaper saved to gallery!',
      );
    } else {
      return DownloadResult(
        success: false,
        message: 'Failed to download image (Status: ${response.statusCode})',
      );
    }
  } catch (e) {
    return DownloadResult(
      success: false,
      message: 'Error saving wallpaper: $e',
    );
  }
}

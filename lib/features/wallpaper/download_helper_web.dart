// downloads images directly from the web browser to the computer
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;
import 'package:moodwalls/features/wallpaper/download_result.dart';
export 'download_result.dart';

Future<DownloadResult> downloadImage(String imageUrl, String filename) async {
  try {
    // add web error handling
    final response = await http.get(Uri.parse(imageUrl)).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw 'Download request timed out';
      },
    );

    if (response.statusCode != 200) {
      return DownloadResult(
        success: false,
        message: 'Failed to download image (Status: ${response.statusCode})',
      );
    }

    final bytes = response.bodyBytes;

    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = '$filename.jpg'
      ..style.display = 'none';

    web.document.body!.appendChild(anchor);
    anchor.click();

    web.document.body!.removeChild(anchor);
    web.URL.revokeObjectURL(url);

    return DownloadResult(
      success: true,
      message: 'Download started!',
    );
  } on Exception catch (e) {
    debugPrint('Download error: $e');
    return DownloadResult(
      success: false,
      message: 'Error: ${e.toString()}',
    );
  } catch (e) {
    debugPrint('Unexpected download error: $e');
    return DownloadResult(
      success: false,
      message: 'Unexpected error: $e',
    );
  }
}

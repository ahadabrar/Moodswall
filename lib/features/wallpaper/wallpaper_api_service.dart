import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_model.dart';

class WallpaperApiService {

  static const Map<String, String> _moodToQuery = {
    'Happy': 'sunset nature flowers bright colorful',
    'Calm': 'ocean beach zen peaceful water',
    'Sad': 'rain clouds dark moody emotional',
    'Energetic': 'city neon lights vibrant urban',
    'Romantic': 'sunset pink flowers love couple',
    'Aesthetic': 'minimal modern clean abstract design',
  };

  static const String _unsplashBaseUrl = 'https://api.unsplash.com';
  static const String _unsplashAccessKey = '2hTxYMzPSdLEaLcbwp1ASnJNG40AI873LHUvVFlbj_E';

  static Future<List<WallpaperModel>> fetchWallpapersFromUnsplash(String mood, {int perPage = 30}) async {
    try {
      final query = _moodToQuery[mood] ?? mood.toLowerCase();
      final url = Uri.parse('$_unsplashBaseUrl/search/photos?query=$query&per_page=$perPage&orientation=portrait');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Client-ID $_unsplashAccessKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isEmpty) {
          debugPrint('No results found for mood: $mood');
          return _getDemoWallpapers(mood);
        }

        return results.map((photo) {
          final imageUrl = photo['urls']?['regular'] ?? photo['urls']?['full'] ?? '';
          final safeId = base64Url.encode(utf8.encode(imageUrl)).replaceAll('=', '');
          return WallpaperModel(
            id: photo['id'] ?? '${mood}_$safeId',
            imageUrl: imageUrl,
            mood: mood,
            tags: [
              mood.toLowerCase(),
              if (photo['tags'] != null)
                ...(photo['tags'] as List).map((tag) => tag['title']?.toString().toLowerCase() ?? '').where((t) => t.isNotEmpty),
            ],
          );
        }).toList();
      } else {
        debugPrint('Unsplash API error: ${response.statusCode} - ${response.body}');
        return _getDemoWallpapers(mood);
      }
    } catch (e) {
      debugPrint('Error fetching from Unsplash: $e');
      return _getDemoWallpapers(mood);
    }
  }

  static Future<List<WallpaperModel>> fetchWallpapersFromPlaceholder(String mood, {int perPage = 20}) async {
    try {

      final seed = mood.hashCode.abs();
      final wallpapers = <WallpaperModel>[];

      for (int i = 0; i < perPage; i++) {
        final imageId = ((seed + i) % 1000) + 1; // 1 to 1000
        final imageUrl = 'https://picsum.photos/id/$imageId/800/1200';
        final safeId = base64Url.encode(utf8.encode(imageUrl)).replaceAll('=', '');
        wallpapers.add(
          WallpaperModel(
            id: '${mood}_$safeId',
            imageUrl: imageUrl,
            mood: mood,
            tags: [mood.toLowerCase()],
          ),
        );
      }

      return wallpapers;
    } catch (e) {
      debugPrint('Error fetching placeholder images: $e');
      return [];
    }
  }

  static List<WallpaperModel> _getDemoWallpapers(String mood) {

    final queries = {
      'Happy': ['sunset', 'nature', 'flowers', 'colorful', 'bright', 'summer'],
      'Calm': ['ocean', 'beach', 'zen', 'peaceful', 'water', 'serene'],
      'Sad': ['rain', 'clouds', 'dark', 'melancholy', 'storm', 'gray'],
      'Energetic': ['city', 'neon', 'vibrant', 'dynamic', 'urban', 'lights'],
      'Romantic': ['sunset', 'pink', 'flowers', 'love', 'rose', 'couple'],
      'Aesthetic': ['minimal', 'modern', 'clean', 'simple', 'abstract', 'design'],
    };

    final keywords = queries[mood] ?? [mood.toLowerCase()];
    final wallpapers = <WallpaperModel>[];

    final baseSeed = mood.hashCode.abs();

    for (int i = 0; i < 30; i++) {
      final keyword = keywords[i % keywords.length];
      final imageId = ((baseSeed + i) % 1000) + 1; // 1 to 1000
      final imageUrl = 'https://picsum.photos/id/$imageId/800/1200';
      final safeId = base64Url.encode(utf8.encode(imageUrl)).replaceAll('=', '');
      wallpapers.add(
        WallpaperModel(
          id: '${mood}_$safeId',
          imageUrl: imageUrl,
          mood: mood,
          tags: [keyword, mood.toLowerCase()],
        ),
      );
    }

    return wallpapers;
  }

  static Future<List<WallpaperModel>> fetchWallpapers(String mood, {int perPage = 30}) async {
    // Skip HTTP calls on web platform due to CORS restrictions
    if (!kIsWeb) {
      try {
        final wallpapers = await fetchWallpapersFromUnsplash(mood, perPage: perPage);
        if (wallpapers.isNotEmpty) {
          return wallpapers;
        }
      } catch (e) {
        debugPrint('Error with Unsplash API, trying fallback: $e');
      }
    }

    try {
      return _getDemoWallpapers(mood);
    } catch (e) {
      debugPrint('Error with demo wallpapers, trying placeholder: $e');

      return fetchWallpapersFromPlaceholder(mood, perPage: perPage);
    }
  }
}


import 'package:flutter/material.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_model.dart';
import 'package:moodwalls/core/firestore_service.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_api_service.dart';

class WallpaperProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<WallpaperModel> _suggestedWallpapers = [];
  List<WallpaperModel> _userWallpapers = [];
  bool _isLoading = false;
  String? _error;

  List<WallpaperModel> get suggestedWallpapers => _suggestedWallpapers;
  List<WallpaperModel> get userWallpapers => _userWallpapers;
  List<WallpaperModel> get allWallpapers => [..._userWallpapers, ..._suggestedWallpapers];

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWallpapersByMood(String mood, {String? uid}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {

      List<WallpaperModel> suggested = await _firestoreService.getWallpapersByMood(mood);
      
      // If we have very few wallpapers in cache, fetch more from the API to fill it up
      if (suggested.length < 15) {
        debugPrint('Cache low (${suggested.length}), fetching more from API for mood: $mood');
        final apiWallpapers = await WallpaperApiService.fetchWallpapers(mood, perPage: 20);
        
        for (var w in apiWallpapers) {
          await _firestoreService.cacheWallpaper(w);
        }
        
        // Re-fetch from firestore to get the updated list
        suggested = await _firestoreService.getWallpapersByMood(mood);
      }
      _suggestedWallpapers = suggested;

      if (uid != null && uid.isNotEmpty) {
        _userWallpapers = await _firestoreService.getUserMoodWallpapersForMood(uid, mood);
      } else {
        _userWallpapers = [];
      }

    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching wallpapers: $e');

      _suggestedWallpapers = await _firestoreService.getWallpapersByMood(mood);
      if (uid != null && uid.isNotEmpty) {
        _userWallpapers = await _firestoreService.getUserMoodWallpapersForMood(uid, mood);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addUserWallpaper({
    required String uid,
    required String mood,
    required String imageUrl,
  }) async {
    await _firestoreService.addUserMoodWallpaper(
      uid: uid,
      mood: mood,
      imageUrl: imageUrl,
      tags: [mood.toLowerCase()],
    );
    await fetchWallpapersByMood(mood, uid: uid);
  }

  Future<void> toggleFavorite(String uid, WallpaperModel wallpaper) async {
    await _firestoreService.toggleFavorite(uid, wallpaper);
  }
}

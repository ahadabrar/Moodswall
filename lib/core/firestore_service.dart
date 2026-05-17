// does all the firebase firestore database operations like saving favorites and moods
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:moodwalls/features/wallpaper/wallpaper_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _getUserCollection(String uid) {
    // this is tricky if we only have the uid
    // firestore service should be independent
    // we know the admin email is moodswalladmin at gmail
    // and its uid will be constant
    // check auth or let it fail
    // pass collection name or check auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (user.email ?? '').toLowerCase() == 'moodswalladmin@gmail.com') {
      return 'admins';
    }
    return 'users';
  }

  CollectionReference<Map<String, dynamic>> _moodWallpapersCol(String uid) {
    return _db.collection('users').doc(uid).collection('mood_wallpapers');
  }

  Future<List<WallpaperModel>> getUserMoodWallpapersForMood(String uid, String mood) async {
    try {
      final snap = await _moodWallpapersCol(uid).where('mood', isEqualTo: mood).get();
      return snap.docs.map((d) {
        final data = d.data();
        return WallpaperModel(
          id: 'user_${d.id}',
          imageUrl: data['imageUrl'] as String? ?? '',
          mood: data['mood'] as String? ?? mood,
          tags: List<String>.from(data['tags'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user mood wallpapers: $e');
      return [];
    }
  }

  Future<String> addUserMoodWallpaper({
    required String uid,
    required String mood,
    required String imageUrl,
    required List<String> tags,
  }) async {
    final doc = await _moodWallpapersCol(uid).add({
      'mood': mood,
      'imageUrl': imageUrl,
      'tags': tags.isEmpty ? [mood.toLowerCase()] : tags,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateUserMoodWallpaper({
    required String uid,
    required String docId,
    required String imageUrl,
    required List<String> tags,
  }) async {
    await _moodWallpapersCol(uid).doc(docId).update({
      'imageUrl': imageUrl,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUserMoodWallpaper(String uid, String docId) async {
    await _moodWallpapersCol(uid).doc(docId).delete();
  }

  Future<WallpaperModel?> _wallpaperByFavoriteId(String uid, String favoriteId) async {
    if (favoriteId.startsWith('user_')) {
      final docId = favoriteId.substring(5);
      final snap = await _moodWallpapersCol(uid).doc(docId).get();
      if (!snap.exists) return null;
      final data = snap.data()!;
      return WallpaperModel(
        id: favoriteId,
        imageUrl: data['imageUrl'] as String? ?? '',
        mood: data['mood'] as String? ?? '',
        tags: List<String>.from(data['tags'] ?? []),
      );
    }
    final snap = await _db.collection('wallpapers').doc(favoriteId).get();
    if (!snap.exists) return null;
    return WallpaperModel.fromSnapshot(snap);
  }

  Future<List<WallpaperModel>> getWallpapersByMood(String mood) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('wallpapers')
          .where('mood', isEqualTo: mood)
          .get();

      return snapshot.docs
          .map((doc) => WallpaperModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting wallpapers: $e');
      return [];
    }
  }

  Future<void> cacheWallpaper(WallpaperModel wallpaper) async {
    try {
      final ref = _db.collection('wallpapers').doc(wallpaper.id);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({
          'imageUrl': wallpaper.imageUrl,
          'mood': wallpaper.mood,
          'tags': wallpaper.tags,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error caching wallpaper: $e');
    }
  }

  Future<void> savePreferredMood(String uid, String mood) async {
    final collection = _getUserCollection(uid);
    await _db.collection(collection).doc(uid).set(
      {'preferredMood': mood},
      SetOptions(merge: true),
    );
  }

  Future<void> toggleFavorite(String uid, WallpaperModel wallpaper) async {
    final collection = _getUserCollection(uid);
    DocumentReference userRef = _db.collection(collection).doc(uid);

    if (!wallpaper.id.startsWith('user_')) {
      DocumentReference wallpaperRef = _db.collection('wallpapers').doc(wallpaper.id);
      final wallpaperDoc = await wallpaperRef.get();
      if (!wallpaperDoc.exists) {
        await wallpaperRef.set({
          'imageUrl': wallpaper.imageUrl,
          'mood': wallpaper.mood,
          'tags': wallpaper.tags,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    var userSnap = await userRef.get();
    if (!userSnap.exists) {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      await userRef.set({
        'email': email,
        'favorites': <String>[],
      }, SetOptions(merge: true));
      userSnap = await userRef.get();
    }

    final data = userSnap.data() as Map<String, dynamic>?;
    final favorites = List<dynamic>.from(data?['favorites'] ?? []);

    if (favorites.contains(wallpaper.id)) {
      await userRef.update({
        'favorites': FieldValue.arrayRemove([wallpaper.id]),
      });
    } else {
      await userRef.update({
        'favorites': FieldValue.arrayUnion([wallpaper.id]),
      });
    }
  }

  Future<List<WallpaperModel>> getFavorites(String uid, List<String> wallpaperIds) async {
    if (wallpaperIds.isEmpty) return [];

    try {
      final List<WallpaperModel> favorites = [];
      for (final id in wallpaperIds) {
        final w = await _wallpaperByFavoriteId(uid, id);
        if (w != null) favorites.add(w);
      }
      return favorites;
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snap = await _db.collection('users').get();
      return snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      // delete from both collections to be safe
      await _db.collection('users').doc(uid).delete();
      await _db.collection('admins').doc(uid).delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  Future<void> createUserRecord({
    required String uid,
    required String email,
    required String username,
    bool isAdmin = false,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'isAdmin': isAdmin,
      'favorites': [],
      'customMoods': [],
      'preferredMood': 'Happy',
    }, SetOptions(merge: true));
  }

  Future<void> updateCustomMoods(String uid, List<String> moods) async {
    await _db.collection('users').doc(uid).set(
      {'customMoods': moods},
      SetOptions(merge: true),
    );
  }

  Future<void> updateProfileImageUrl(String uid, String url) async {
    final collection = _getUserCollection(uid);
    await _db.collection(collection).doc(uid).set(
      {'profileImageUrl': url},
      SetOptions(merge: true),
    );
  }

  Future<void> addDailyMood(String uid, String mood, String dateString, {String? title, String? note}) async {
    await _db.collection('users').doc(uid).collection('mood_history').doc(dateString).set({
      'mood': mood,
      'title': title ?? '',
      'note': note ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // also add to public feed
    await _db.collection('public_feed').add({
      'mood': mood,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, Map<String, String>>> getMoodHistoryWithNotes(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).collection('mood_history').get();
      Map<String, Map<String, String>> history = {};
      for (var doc in snap.docs) {
        final data = doc.data();
        history[doc.id] = {
          'mood': data['mood'] as String,
          'title': data['title'] as String? ?? '',
          'note': data['note'] as String? ?? '',
        };
      }
      return history;
    } catch (e) {
      debugPrint('Error getting mood history: $e');
      return {};
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPublicMoodFeed() {
    return _db.collection('public_feed')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }
}

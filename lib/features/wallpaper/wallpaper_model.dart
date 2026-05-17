// model to represent a single wallpaper with its id url mood and tags
import 'package:cloud_firestore/cloud_firestore.dart';

class WallpaperModel {
  final String id;
  final String imageUrl;
  final String mood;
  final List<String> tags;

  WallpaperModel({
    required this.id,
    required this.imageUrl,
    required this.mood,
    required this.tags,
  });

  factory WallpaperModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WallpaperModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      mood: data['mood'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
}

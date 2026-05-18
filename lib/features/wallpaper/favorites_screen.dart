// shows a grid layout of all wallpapers marked as favorites by the user
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:moodwalls/features/auth/auth_provider.dart';
import 'package:moodwalls/core/firestore_service.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_model.dart';
import 'package:moodwalls/features/wallpaper/8_preview_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final userModel = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
      ),
      body: user == null || userModel == null
          ? const Center(child: Text('Sign in to see favorites.'))
          : userModel.favorites.isEmpty
              ? const Center(
                  child: Text('No favorites yet! Go explore.'),
                )
              : FutureBuilder<List<WallpaperModel>>(
              future: FirestoreService().getFavorites(user.uid, userModel.favorites),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final wallpapers = snapshot.data ?? [];

                if (wallpapers.isEmpty) {
                   return const Center(child: Text('No favorites found.'));
                }

                return MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  padding: const EdgeInsets.all(8),
                  itemCount: wallpapers.length,
                  itemBuilder: (context, index) {
                     final wallpaper = wallpapers[index];
                     return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreviewScreen(wallpaper: wallpaper),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            CachedNetworkImage(
                              imageUrl: wallpaper.imageUrl,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                height: 200,
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  wallpaper.mood,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

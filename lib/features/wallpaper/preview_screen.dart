// full screen preview of a wallpaper with download and favorite buttons
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_model.dart';
import 'package:moodwalls/features/auth/auth_provider.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_provider.dart';

import 'package:moodwalls/features/wallpaper/download_helper_stub.dart'
    if (dart.library.html) 'package:moodwalls/features/wallpaper/download_helper_web.dart'
    if (dart.library.io) 'package:moodwalls/features/wallpaper/download_helper_mobile.dart' as download_helper;

class PreviewScreen extends StatefulWidget {
  final WallpaperModel wallpaper;

  const PreviewScreen({super.key, required this.wallpaper});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {

  Future<void> _downloadWallpaper(BuildContext context) async {
    try {
      final result = await download_helper.downloadImage(
        widget.wallpaper.imageUrl,
        widget.wallpaper.id,
      );

      if (!context.mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _toggleFavorite(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      Provider.of<WallpaperProvider>(context, listen: false)
          .toggleFavorite(user.uid, widget.wallpaper);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorites updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.wallpaper.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                _buildActionButton(
                  context,
                  icon: Icons.download,
                  label: 'Save',
                  onTap: () => _downloadWallpaper(context),
                ),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final isFav = authProvider.userModel?.favorites.contains(widget.wallpaper.id) ?? false;
                    return _buildActionButton(
                      context,
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      label: 'Fav',
                      iconColor: isFav ? Colors.red : Colors.black87,
                      onTap: () => _toggleFavorite(context),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    bool isLoading = false,
    Color iconColor = Colors.black87,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: label,
            backgroundColor: Colors.white,
            onPressed: isLoading ? null : onTap,
            elevation: 0,
            child: isLoading 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
          label, 
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        ),
      ],
    );
  }
}

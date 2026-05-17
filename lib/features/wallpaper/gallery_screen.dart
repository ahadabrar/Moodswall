// shows available wallpapers for the selected mood
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moodwalls/features/auth/auth_provider.dart';
import 'package:moodwalls/features/mood/mood_theme_provider.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_provider.dart';
import '../../config/theme.dart';
import 'package:moodwalls/features/mood/mood_scaffold_background.dart';
import 'package:moodwalls/features/wallpaper/wallpaper_model.dart';
import 'package:moodwalls/features/wallpaper/preview_screen.dart';

class GalleryScreen extends StatefulWidget {
  final String mood;

  const GalleryScreen({super.key, required this.mood});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MoodThemeProvider>().setMoodByTitle(widget.mood);
      context.read<WallpaperProvider>().fetchWallpapersByMood(
            widget.mood,
            uid: context.read<AuthProvider>().user?.uid,
          );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodCfg = context.watch<MoodThemeProvider>().forTitle(widget.mood);
    return MoodScaffoldBackground(
      mood: moodCfg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '${widget.mood} Wallpapers',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              ),
            ),
            Consumer<WallpaperProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_getMoodColor(widget.mood)),
                      ),
                    ),
                  );
                }

                if (provider.error != null) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${provider.error}')),
                  );
                }

                final List<Widget> slivers = [];

                if (provider.suggestedWallpapers.isNotEmpty) {
                  slivers.add(const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Suggested',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ));
                  slivers.add(SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemBuilder: (context, index) {
                        final wallpaper = provider.suggestedWallpapers[index];
                        return _buildWallpaperCard(context, wallpaper, index);
                      },
                      childCount: provider.suggestedWallpapers.length,
                    ),
                  ));
                }

                if (slivers.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No wallpapers found')),
                  );
                }

                return SliverMainAxisGroup(slivers: slivers);
              },
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildWallpaperCard(BuildContext context, WallpaperModel wallpaper, int index) {
    return Hero(
      tag: 'wallpaper_${wallpaper.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreviewScreen(wallpaper: wallpaper),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: wallpaper.imageUrl,
                  placeholder: (context, url) => Container(
                    height: 200 + (index % 3) * 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[200]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey[400]!,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error_outline, color: Colors.grey),
                  ),
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.mood,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return AppTheme.pastelYellow;
      case 'Calm':
        return AppTheme.pastelBlue;
      case 'Sad':
        return const Color(0xFFB0C4DE);
      case 'Energetic':
        return AppTheme.pastelPeach;
      case 'Romantic':
        return AppTheme.pastelPink;
      case 'Aesthetic':
        return AppTheme.pastelLavender;
      default:
        return AppTheme.pastelBlue;
    }
  }
}

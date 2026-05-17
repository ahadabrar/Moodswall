// main home page where you choose your mood and see affirmations
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:moodwalls/features/auth/user_model.dart';
import 'package:moodwalls/features/auth/auth_provider.dart';
import 'package:moodwalls/features/mood/mood_theme_provider.dart';
import 'package:moodwalls/core/firestore_service.dart';
import 'package:moodwalls/features/mood/mood_card.dart';
import 'package:moodwalls/features/mood/mood_scaffold_background.dart';
import 'package:moodwalls/features/wallpaper/favorites_screen.dart';
import 'package:moodwalls/features/admin/admin_dashboard.dart';
import 'package:moodwalls/features/mood/affirmation_service.dart';
import 'package:moodwalls/features/home/mood_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _scheduledProfileHydrate = false;
  final FirestoreService _firestore = FirestoreService();

  void _hydrateMoodFromProfile(UserModel? userModel) {
    if (_scheduledProfileHydrate || userModel == null) return;
    _scheduledProfileHydrate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pref = context.read<AuthProvider>().userModel?.preferredMood;
      if (pref != null && pref.isNotEmpty) {
        context.read<MoodThemeProvider>().setMoodByTitle(pref);
      }
    });
  }



  Future<void> _onMoodTap(BuildContext context, String moodTitle, String? uid) async {
    if (!context.mounted) return;
    context.read<MoodThemeProvider>().setMoodByTitle(moodTitle);
    
    if (uid != null) {
      await _firestore.savePreferredMood(uid, moodTitle);
      final dateString = DateTime.now().toString().substring(0, 16); 
      await _firestore.addDailyMood(
        uid, 
        moodTitle, 
        dateString, 
      );
    }
    
    if (!context.mounted) return;
    await Navigator.pushNamed(
      context,
      '/gallery',
      arguments: moodTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userModel = context.watch<AuthProvider>().userModel;
    _hydrateMoodFromProfile(userModel);

    final email = (user?.email ?? '').toLowerCase();
    if (userModel?.isAdmin == true || email == 'moodswalladmin@gmail.com') {
      return const AdminDashboardScreen();
    }

    return Consumer<MoodThemeProvider>(
      builder: (context, moodTheme, _) {
        final mood = moodTheme.current;
        final presets = moodTheme.moods;

        return MoodScaffoldBackground(
          mood: mood,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/mood-history'),
              icon: const Icon(Icons.book),
              label: const Text('Write Diary'),
              backgroundColor: mood.accent,
              foregroundColor: Colors.white,
            ),
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'MoodWalls',
                      style: TextStyle(
                        color: mood.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.public, color: Colors.black87),
                      tooltip: 'Community Feed',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodFeedScreen())),
                    ),

                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.black87),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.black87),
                      onPressed: () => Navigator.pushNamed(context, '/mood-history'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.black87),
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.black87),
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          _getGreeting(userModel, user?.email ?? ''),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 28,
                              ),
                        ),
                         const SizedBox(height: 8),
                        const Text(
                          'How are you feeling today?',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        // affirmation card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: mood.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: mood.accent.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.format_quote, color: mood.accent),
                                  const SizedBox(width: 8),
                                  const Text('Daily Affirmation', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AffirmationService.getAffirmation(mood.title),
                                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.70,
                          ),
                          itemCount: presets.length,
                          itemBuilder: (context, index) {
                            final cfg = presets[index];
                            return MoodCard(
                              title: cfg.title,
                              emoji: cfg.emoji,
                              color: cfg.accent,
                              onTap: () => _onMoodTap(context, cfg.title, user?.uid),
                            );
                          },
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getGreeting(UserModel? userModel, String email) {
    if (userModel?.username != null && userModel!.username!.isNotEmpty) {
      return 'Hello, ${userModel.username}! 👋';
    }
    if (email.isEmpty) {
      return 'Hello! 👋';
    }
    final name = email.split('@').first;
    final displayName = name.isNotEmpty
        ? name[0].toUpperCase() + (name.length > 1 ? name.substring(1) : '')
        : '';
    return 'Hello, $displayName! 👋';
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodwalls/core/firestore_service.dart';
import 'package:moodwalls/features/mood/mood_theme_provider.dart';

class MoodFeedScreen extends StatelessWidget {
  const MoodFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Mood Feed'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.getPublicMoodFeed(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No moods yet. Be the first!'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final moodTitle = data['mood'] as String;
              final timestamp = data['timestamp'] as Timestamp?;
              final moodConfig = MoodThemeProvider.presetForTitle(moodTitle);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: moodConfig.accent.withValues(alpha: 0.2),
                    child: Text(moodConfig.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(
                    'Someone is feeling $moodTitle',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    timestamp != null ? _formatTime(timestamp.toDate()) : 'Just now',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

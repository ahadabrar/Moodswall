import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moodwalls/features/auth/auth_provider.dart';
import 'package:moodwalls/features/mood/mood_theme_provider.dart';
import 'package:moodwalls/core/firestore_service.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  final FirestoreService _firestore = FirestoreService();
  Map<String, Map<String, String>> _history = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _showDiaryDialog(BuildContext context, String? uid) async {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final currentMood = context.read<MoodThemeProvider>().current.title;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Diary Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Title for your diary...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Write a paragraph about your day...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {
              'title': titleController.text,
              'note': noteController.text,
            }),
            child: const Text('Save Diary'),
          ),
        ],
      ),
    );

    if (result != null && uid != null && context.mounted) {
      final dateString = DateTime.now().toString().substring(0, 16); 
      await _firestore.addDailyMood(
        uid, 
        currentMood, 
        dateString, 
        title: result['title'],
        note: result['note'],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary saved successfully!')),
      );
      _fetchHistory(); // Refresh the list
    }
  }

  Future<void> _fetchHistory() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      final history = await _firestore.getMoodHistoryWithNotes(uid);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = _history.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // Simple Analytics: Count most frequent mood
    String mostFrequentMood = 'N/A';
    if (_history.isNotEmpty) {
      final counts = <String, int>{};
      for (var entry in _history.values) {
        counts[entry['mood']!] = (counts[entry['mood']!] ?? 0) + 1;
      }
      mostFrequentMood = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final uid = context.read<AuthProvider>().user?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diary & History'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDiaryDialog(context, uid),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    'No history yet.\nStart tracking by selecting a mood!',
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    // Mood Trend Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlue],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.white, size: 40),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Most Frequent Mood',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              Text(
                                mostFrequentMood,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, index) {
                          final date = sortedKeys[index];
                          final data = _history[date]!;
                          final mood = data['mood']!;
                          final title = data['title'] ?? '';
                          final note = data['note'] ?? '';
                          final moodConfig = MoodThemeProvider.presetForTitle(mood);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: moodConfig.accent.withValues(alpha: 0.1),
                                child: Text(moodConfig.emoji),
                              ),
                              title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Chip(
                                label: Text(mood),
                                backgroundColor: moodConfig.accent.withValues(alpha: 0.1),
                              ),
                              children: [
                                if (title.isNotEmpty || note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (title.isNotEmpty) ...[
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          if (note.isNotEmpty)
                                            Text(
                                              note,
                                              style: TextStyle(color: Colors.grey[800]),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('No diary entry added for this time.', style: TextStyle(color: Colors.grey)),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:moodwalls/features/wallpaper/wallpaper_model.dart';
import 'package:moodwalls/features/auth/auth_provider.dart';
import 'package:moodwalls/features/mood/mood_theme_provider.dart';
import 'package:moodwalls/core/firestore_service.dart';
import 'package:moodwalls/core/validators.dart';

class MyMoodWallpapersScreen extends StatefulWidget {
  const MyMoodWallpapersScreen({super.key});

  @override
  State<MyMoodWallpapersScreen> createState() => _MyMoodWallpapersScreenState();
}

class _MyMoodWallpapersScreenState extends State<MyMoodWallpapersScreen> {
  final FirestoreService _firestore = FirestoreService();
  String _mood = MoodThemeProvider.presets.first.title;

  Future<void> _confirmDelete(String uid, WallpaperModel w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete wallpaper?'),
        content: const Text(
          'This removes your custom entry from Firestore. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final rawId = w.id.startsWith('user_') ? w.id.substring(5) : w.id;
    try {
      await _firestore.deleteUserMoodWallpaper(uid, rawId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  Future<void> _showEditor({WallpaperModel? existing}) async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in')),
      );
      return;
    }

    final urlCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final tagsCtrl = TextEditingController(text: existing?.tags.join(', ') ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add wallpaper' : 'Edit wallpaper'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) => Validators.imageUrl(v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (optional)',
                    hintText: 'e.g. ocean, blue',
                  ),
                  validator: (v) => Validators.optionalTags(v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final tags = tagsCtrl.text
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      if (existing == null) {
        await _firestore.addUserMoodWallpaper(
          uid: uid,
          mood: _mood,
          imageUrl: urlCtrl.text.trim(),
          tags: tags,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper added')),
        );
      } else {
        final rawId = existing.id.startsWith('user_') ? existing.id.substring(5) : existing.id;
        await _firestore.updateUserMoodWallpaper(
          uid: uid,
          docId: rawId,
          imageUrl: urlCtrl.text.trim(),
          tags: tags.isEmpty ? [_mood.toLowerCase()] : tags,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My mood wallpapers'),
      ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showEditor(),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add'),
            ),
      body: uid == null
          ? const Center(child: Text('Sign in to manage your wallpapers.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: DropdownButtonFormField<String>(
                    initialValue: _mood,
                    decoration: const InputDecoration(
                      labelText: 'Mood',
                      border: OutlineInputBorder(),
                    ),
                    items: MoodThemeProvider.presets
                        .map((m) => DropdownMenuItem(value: m.title, child: Text('${m.emoji} ${m.title}')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _mood = v);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Create, edit, or delete your own wallpaper links for each mood (stored in Firestore).',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('mood_wallpapers')
                        .where('mood', isEqualTo: _mood)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                        snap.data!.docs,
                      )..sort((a, b) {
                          final ta = a.data()['createdAt'];
                          final tb = b.data()['createdAt'];
                          if (ta is Timestamp && tb is Timestamp) {
                            return tb.compareTo(ta);
                          }
                          return 0;
                        });
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('No custom wallpapers yet. Tap Add.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final data = doc.data();
                          final url = data['imageUrl'] as String? ?? '';
                          final tags = List<String>.from(data['tags'] ?? []);
                          final w = WallpaperModel(
                            id: 'user_${doc.id}',
                            imageUrl: url,
                            mood: data['mood'] as String? ?? _mood,
                            tags: tags,
                          );
                          return Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                              title: Text(
                                url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(tags.isEmpty ? '—' : tags.join(', ')),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showEditor(existing: w),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmDelete(uid, w),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

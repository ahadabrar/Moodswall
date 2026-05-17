// manages mood presets emojis color gradients and theme states
import 'package:flutter/material.dart';

class MoodThemeConfig {
  final String title;
  final String emoji;
  final Color accent;
  final List<Color> scaffoldGradient;
  final String backgroundImageUrl;

  const MoodThemeConfig({
    required this.title,
    required this.emoji,
    required this.accent,
    required this.scaffoldGradient,
    required this.backgroundImageUrl,
  });
}

class MoodThemeProvider extends ChangeNotifier {
  MoodThemeProvider();

  static const List<MoodThemeConfig> presets = [
    MoodThemeConfig(
      title: 'Happy',
      emoji: '😊',
      accent: Color(0xFFFFC107),
      scaffoldGradient: [
        Color(0xFFFFF9E6),
        Color(0xFFFFF3C4),
        Color(0xFFFFFFFF),
      ],
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1490730141103-6cac27aaab94',
    ),
    MoodThemeConfig(
      title: 'Calm',
      emoji: '😌',
      accent: Color(0xFF4FC3F7),
      scaffoldGradient: [
        Color(0xFFE3F2FD),
        Color(0xFFB3E5FC),
        Color(0xFFFFFFFF),
      ],
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1471922694854-ff1b63b20054',
    ),
    MoodThemeConfig(
      title: 'Sad',
      emoji: '😢',
      accent: Color(0xFF90A4AE),
      scaffoldGradient: [
        Color(0xFFECEFF1),
        Color(0xFFCFD8DC),
        Color(0xFFFFFFFF),
      ],
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1428592953211-077101b2021b',
    ),
    MoodThemeConfig(
      title: 'Energetic',
      emoji: '⚡',
      accent: Color(0xFFFF7043),
      scaffoldGradient: [
        Color(0xFFFFF3E0),
        Color(0xFFFFE0B2),
        Color(0xFFFFFFFF),
      ],
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1534447677768-be436bb09401',
    ),
    MoodThemeConfig(
      title: 'Romantic',
      emoji: '💖',
      accent: Color(0xFFEC407A),
      scaffoldGradient: [
        Color(0xFFFCE4EC),
        Color(0xFFF8BBD0),
        Color(0xFFFFFFFF),
      ],
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1518173946687-a4c8892bbd9f',
    ),
    MoodThemeConfig(
      title: 'Aesthetic',
      emoji: '✨',
      accent: Color(0xFF9575CD),
      scaffoldGradient: [
        Color(0xFFF3E5F5),
        Color(0xFFE1BEE7),
        Color(0xFFFFFFFF),
      ],
      backgroundImageUrl:
          'https://images.unsplash.com/photo-1550684848-fac1c5b4e853',
    ),
  ];

  final List<MoodThemeConfig> _moods = List<MoodThemeConfig>.from(presets);

  MoodThemeConfig _current = presets.first;

  MoodThemeConfig get current => _current;

  List<MoodThemeConfig> get moods => List.unmodifiable(_moods);

  static MoodThemeConfig get defaultMood => presets.first;

  MoodThemeConfig forTitle(String title) {
    for (final m in _moods) {
      if (m.title == title) return m;
    }
    return defaultMood;
  }

  static MoodThemeConfig presetForTitle(String title) {
    for (final m in presets) {
      if (m.title == title) return m;
    }
    return defaultMood;
  }

  void setMoodByTitle(String title) {
    MoodThemeConfig next = defaultMood;
    for (final m in _moods) {
      if (m.title == title) {
        next = m;
        break;
      }
    }
    if (next.title != _current.title) {
      _current = next;
      notifyListeners();
    }
  }

  void addMood(MoodThemeConfig mood) {
    if (mood.title.isEmpty) return;
    if (_moods.any((existing) => existing.title.toLowerCase() == mood.title.toLowerCase())) return;
    _moods.add(mood);
    notifyListeners();
  }

  void removeMood(String title) {
    if (_moods.length <= 1) return;
    _moods.removeWhere((m) => m.title == title);
    if (_current.title == title) {
      _current = _moods.first;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }
}

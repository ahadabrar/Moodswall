import 'package:flutter/material.dart';
import 'package:moodwalls/features/mood/mood_theme_provider.dart';

class MoodScaffoldBackground extends StatelessWidget {
  final MoodThemeConfig mood;
  final Widget child;

  const MoodScaffoldBackground({
    super.key,
    required this.mood,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.network(
            mood.backgroundImageUrl,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return ColoredBox(color: mood.scaffoldGradient.first);
            },
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  mood.scaffoldGradient.first.withValues(alpha: 0.92),
                  mood.scaffoldGradient[1].withValues(alpha: 0.88),
                  mood.scaffoldGradient.last,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

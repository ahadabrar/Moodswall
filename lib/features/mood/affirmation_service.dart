// returns a nice positive affirmation phrase based on current mood
import 'dart:math';

class AffirmationService {
  static const Map<String, List<String>> _affirmations = {
    'Happy': [
      "I am deserving of happiness and joy.",
      "My happiness is a reflection of my inner peace.",
      "Today is a wonderful day to be alive.",
    ],
    'Calm': [
      "I breathe in peace and breathe out tension.",
      "I am centered, grounded, and at peace.",
      "Quietness is my strength.",
    ],
    'Sad': [
      "It's okay not to be okay. This too shall pass.",
      "I am gentle with myself as I heal.",
      "Every day is a fresh start.",
    ],
    'Energetic': [
      "I have the power to create the life I want.",
      "My energy is limitless and focused.",
      "I am unstoppable.",
    ],
    'Romantic': [
      "I am worthy of deep, meaningful love.",
      "Love flows to me and through me.",
      "My heart is open to the beauty of connection.",
    ],
    'Aesthetic': [
      "I find beauty in every moment.",
      "I am the creator of my own beautiful reality.",
      "My life is a work of art.",
    ],
  };

  static String getAffirmation(String mood) {
    final list = _affirmations[mood] ?? _affirmations['Happy']!;
    return list[Random().nextInt(list.length)];
  }
}

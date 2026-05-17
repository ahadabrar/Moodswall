// user model to hold info like email username and favorites
class UserModel {
  final String uid;
  final String email;
  final String? username;
  final List<String> favorites;

  final String? preferredMood;
  final String? profileImageUrl;
  final bool isAdmin;
  final List<String> customMoods;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.favorites = const [],
    this.preferredMood,
    this.profileImageUrl,
    this.isAdmin = false,
    this.customMoods = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'],
      favorites: List<String>.from(data['favorites'] ?? []),
      preferredMood: data['preferredMood'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      isAdmin: data['isAdmin'] ?? false,
      customMoods: List<String>.from(data['customMoods'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (username != null) 'username': username,
      'favorites': favorites,
      if (preferredMood != null) 'preferredMood': preferredMood,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'isAdmin': isAdmin,
      'customMoods': customMoods,
    };
  }
}

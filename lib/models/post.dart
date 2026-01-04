import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String odiserId;
  final String userName;
  final String? userPhotoUrl;
  final String message;
  final String? imageUrl;
  final int likes;
  final List<String> likedBy;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.odiserId,
    required this.userName,
    this.userPhotoUrl,
    required this.message,
    this.imageUrl,
    required this.likes,
    required this.likedBy,
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map, String id) {
    return Post(
      id: id,
      odiserId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonim',
      userPhotoUrl: map['userPhotoUrl'],
      message: map['message'] ?? '',
      imageUrl: map['imageUrl'],
      likes: map['likes'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': odiserId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'message': message,
      'imageUrl': imageUrl,
      'likes': likes,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

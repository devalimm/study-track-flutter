import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Profil fotoğrafı yükle
  Future<String?> uploadProfilePhoto(String userId, File file) async {
    try {
      final ref = _storage.ref().child('users/$userId/profile.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Profil fotoğrafı yükleme hatası: $e');
      return null;
    }
  }

  // Post görseli yükle
  Future<String?> uploadPostImage(String postId, File file) async {
    try {
      final ref = _storage.ref().child('posts/$postId/image.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Post görseli yükleme hatası: $e');
      return null;
    }
  }

  // Görsel sil
  Future<void> deleteImage(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      print('Görsel silme hatası: $e');
    }
  }
}

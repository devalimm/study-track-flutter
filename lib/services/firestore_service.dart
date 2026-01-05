import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/study_session.dart';
import '../models/goal.dart';
import '../models/post.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== USERS ====================
  
  // Kullanıcı profili oluştur
  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Kullanıcı profili getir
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  // Kullanıcı profili güncelle
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ==================== STUDY SESSIONS ====================

  // Çalışma oturumu ekle
  Future<void> addStudySession(StudySession session) async {
    await _db.collection('study_sessions').doc(session.id).set(session.toMap());
  }

  // Kullanıcının bugünkü oturumlarını getir
  Future<List<StudySession>> getTodaysSessions(String odiserId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // Sadece userId'ye göre filtrele, tarih filtresini client-side yap
    final snapshot = await _db
        .collection('study_sessions')
        .where('userId', isEqualTo: odiserId)
        .get();

    final allSessions = snapshot.docs
        .map((doc) => StudySession.fromMap(doc.data(), doc.id))
        .toList();

    // Bugünün oturumlarını filtrele
    return allSessions.where((session) {
      return session.date.year == startOfDay.year &&
             session.date.month == startOfDay.month &&
             session.date.day == startOfDay.day;
    }).toList();
  }

  // Son 7 günün oturumlarını getir
  Future<List<StudySession>> getWeeklySessions(String odiserId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Sadece userId'ye göre filtrele
    final snapshot = await _db
        .collection('study_sessions')
        .where('userId', isEqualTo: odiserId)
        .get();

    final allSessions = snapshot.docs
        .map((doc) => StudySession.fromMap(doc.data(), doc.id))
        .toList();

    // Son 7 günün oturumlarını filtrele ve sırala
    final weeklySessions = allSessions.where((session) {
      return session.date.isAfter(weekAgo) || 
             session.date.isAtSameMomentAs(weekAgo);
    }).toList();

    weeklySessions.sort((a, b) => b.date.compareTo(a.date));
    return weeklySessions;
  }

  // ==================== GOALS ====================

  // Hedef oluştur veya güncelle
  Future<void> setGoal(Goal goal) async {
    await _db.collection('goals').doc(goal.odiserId).set(goal.toMap());
  }

  // Kullanıcının hedefini getir
  Future<Goal?> getGoal(String odiserId) async {
    final doc = await _db.collection('goals').doc(odiserId).get();
    if (doc.exists) {
      return Goal.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // ==================== POSTS ====================

  // Post ekle
  Future<void> addPost(Post post) async {
    await _db.collection('posts').doc(post.id).set(post.toMap());
  }

  // Tüm postları getir (en yeniden en eskiye)
  Stream<List<Post>> getPostsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Beğen/Beğenmekten vazgeç
  Future<void> toggleLike(String postId, String odiserId) async {
    final postRef = _db.collection('posts').doc(postId);
    
    await _db.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
      
      if (likedBy.contains(odiserId)) {
        likedBy.remove(odiserId);
      } else {
        likedBy.add(odiserId);
      }

      transaction.update(postRef, {
        'likedBy': likedBy,
        'likes': likedBy.length,
      });
    });
  }

  // Post sil
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }
}

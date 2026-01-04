import 'package:cloud_firestore/cloud_firestore.dart';

class StudySession {
  final String id;
  final String odiserId;
  final String subject;
  final int durationMinutes;
  final DateTime date;
  final DateTime createdAt;

  StudySession({
    required this.id,
    required this.odiserId,
    required this.subject,
    required this.durationMinutes,
    required this.date,
    required this.createdAt,
  });

  factory StudySession.fromMap(Map<String, dynamic> map, String id) {
    return StudySession(
      id: id,
      odiserId: map['userId'] ?? '',
      subject: map['subject'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': odiserId,
      'subject': subject,
      'durationMinutes': durationMinutes,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

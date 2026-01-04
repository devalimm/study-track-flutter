import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String odiserId;
  final int dailyTargetMinutes;
  final int weeklyTargetMinutes;
  final Map<String, int>? subjectGoals;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.odiserId,
    required this.dailyTargetMinutes,
    required this.weeklyTargetMinutes,
    this.subjectGoals,
    required this.updatedAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map, String id) {
    return Goal(
      id: id,
      odiserId: map['userId'] ?? '',
      dailyTargetMinutes: map['dailyTargetMinutes'] ?? 60,
      weeklyTargetMinutes: map['weeklyTargetMinutes'] ?? 420,
      subjectGoals: map['subjectGoals'] != null 
          ? Map<String, int>.from(map['subjectGoals']) 
          : null,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': odiserId,
      'dailyTargetMinutes': dailyTargetMinutes,
      'weeklyTargetMinutes': weeklyTargetMinutes,
      'subjectGoals': subjectGoals,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Goal copyWith({
    int? dailyTargetMinutes,
    int? weeklyTargetMinutes,
    Map<String, int>? subjectGoals,
  }) {
    return Goal(
      id: id,
      odiserId: odiserId,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      weeklyTargetMinutes: weeklyTargetMinutes ?? this.weeklyTargetMinutes,
      subjectGoals: subjectGoals ?? this.subjectGoals,
      updatedAt: DateTime.now(),
    );
  }
}

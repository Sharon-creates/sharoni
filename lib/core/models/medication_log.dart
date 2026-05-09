class MedicationLog {
  final String id;
  final String medicationId;
  final String userId;
  final String status; // 'taken', 'missed', 'skipped'
  final DateTime scheduledFor;
  final DateTime loggedAt;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.userId,
    required this.status,
    required this.scheduledFor,
    required this.loggedAt,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'],
      medicationId: json['medication_id'],
      userId: json['user_id'],
      status: json['status'],
      scheduledFor: json['scheduled_for'] is String 
          ? DateTime.parse(json['scheduled_for']) 
          : (json['scheduled_for'] as DateTime),
      loggedAt: json['logged_at'] is String 
          ? DateTime.parse(json['logged_at']) 
          : (json['logged_at'] as DateTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'medication_id': medicationId,
      'user_id': userId,
      'status': status,
      'scheduled_for': scheduledFor.toIso8601String(),
      'logged_at': loggedAt.toIso8601String(),
    };
  }
}

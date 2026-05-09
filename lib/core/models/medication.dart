import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosagePerIntake;
  final List<TimeOfDay> scheduledTimes;
  final int? totalQuantity;
  final int? remainingQuantity;
  final int? durationDays;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isEnabled;
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosagePerIntake,
    required this.scheduledTimes,
    this.totalQuantity,
    this.remainingQuantity,
    this.durationDays,
    required this.startDate,
    this.endDate,
    this.isEnabled = true,
    required this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    final List<dynamic> timesList = json['scheduled_times'] ?? [];
    final List<TimeOfDay> scheduledTimes = timesList.map((t) {
      final parts = (t as String).split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }).toList();

    return Medication(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      dosagePerIntake: json['dosage_per_intake'],
      scheduledTimes: scheduledTimes,
      totalQuantity: json['total_quantity'],
      remainingQuantity: json['remaining_quantity'],
      durationDays: json['duration_days'],
      startDate: json['start_date'] is String 
          ? DateTime.parse(json['start_date']) 
          : (json['start_date'] as DateTime),
      endDate: json['end_date'] == null 
          ? null 
          : (json['end_date'] is String 
              ? DateTime.parse(json['end_date']) 
              : (json['end_date'] as DateTime)),
      isEnabled: json['is_enabled'] ?? true,
      createdAt: json['created_at'] is String 
          ? DateTime.parse(json['created_at']) 
          : (json['created_at'] as DateTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'name': name,
      'dosage_per_intake': dosagePerIntake,
      'scheduled_times': scheduledTimes.map((t) {
        final hour = t.hour.toString().padLeft(2, '0');
        final minute = t.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }).toList(),
      'total_quantity': totalQuantity,
      'remaining_quantity': remainingQuantity,
      'duration_days': durationDays,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Medication copyWith({
    String? name,
    String? dosagePerIntake,
    List<TimeOfDay>? scheduledTimes,
    int? totalQuantity,
    int? remainingQuantity,
    int? durationDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? isEnabled,
  }) {
    return Medication(
      id: id,
      userId: userId,
      name: name ?? this.name,
      dosagePerIntake: dosagePerIntake ?? this.dosagePerIntake,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
    );
  }
}

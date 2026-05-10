import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/features/auth/presentation/auth_controller.dart';
import 'package:sharoni/features/medication/data/medication_repository.dart';
import 'package:sharoni/core/models/medication.dart';
import 'package:sharoni/core/models/medication_log.dart';

import 'package:sharoni/core/services/notification_service.dart';
import 'package:sharoni/core/services/messaging_service.dart';
import 'package:sharoni/features/profile/presentation/profile_controller.dart';
import 'package:sharoni/core/models/profile.dart';

final medicationControllerProvider = StateNotifierProvider<MedicationController, AsyncValue<List<Medication>>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final profile = ref.watch(profileControllerProvider).value;
  final userId = user?.id;
  return MedicationController(
    ref.watch(medicationRepositoryProvider), 
    NotificationService(),
    MessagingService(),
    userId,
    profile,
  );
});

final medicationLogsProvider = FutureProvider<List<MedicationLog>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return [];
  return ref.watch(medicationRepositoryProvider).getTodaysLogs(user.id);
});

class MedicationController extends StateNotifier<AsyncValue<List<Medication>>> {
  final MedicationRepository _repository;
  final NotificationService _notificationService;
  final MessagingService _messagingService;
  final String? _userId;
  final Profile? _profile;

  MedicationController(this._repository, this._notificationService, this._messagingService, this._userId, this._profile) : super(const AsyncValue.loading()) {
    if (_userId != null && _userId!.isNotEmpty) {
      loadMedications();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadMedications() async {
    if (_userId == null || _userId!.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final meds = await _repository.getMedications(_userId!);
      if (mounted) {
        state = AsyncValue.data(meds);
        _syncNotifications(meds);
        checkMissedDoses(meds);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _syncNotifications(List<Medication> meds) {
    for (final med in meds) {
      if (med.isEnabled) {
        _notificationService.scheduleMedicationNotifications(med);
      } else {
        _notificationService.cancelMedicationNotifications(med);
      }
    }
  }

  Future<void> addMedication({
    required String name,
    required String dosagePerIntake,
    required List<TimeOfDay> scheduledTimes,
    int? totalQuantity,
    int? durationDays,
  }) async {
    if (_userId == null) return;
    try {
      int? calculatedDuration = durationDays;
      if (totalQuantity != null && durationDays == null) {
        final dosageValue = double.tryParse(dosagePerIntake.split(' ').first) ?? 1;
        calculatedDuration = (totalQuantity / (dosageValue * scheduledTimes.length)).ceil();
      }

      final now = DateTime.now();
      final newMed = Medication(
        id: '', 
        userId: _userId!,
        name: name,
        dosagePerIntake: dosagePerIntake,
        scheduledTimes: scheduledTimes,
        totalQuantity: totalQuantity,
        remainingQuantity: totalQuantity,
        durationDays: calculatedDuration,
        startDate: now,
        endDate: calculatedDuration != null ? now.add(Duration(days: calculatedDuration)) : null,
        createdAt: now,
      );
      await _repository.addMedication(newMed);
      await loadMedications();
      
      // Schedule notifications for the new medication if enabled
      if (newMed.isEnabled) {
        _notificationService.scheduleMedicationNotifications(newMed);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> logDose(String medicationId, DateTime scheduledFor, String status) async {
    if (_userId == null) return;
    try {
      final log = MedicationLog(
        id: '',
        medicationId: medicationId,
        userId: _userId!,
        status: status,
        scheduledFor: scheduledFor,
        loggedAt: DateTime.now(),
      );
      await _repository.logMedicationDose(log);
      
      if (status == 'taken') {
        final meds = state.value ?? [];
        final medIndex = meds.indexWhere((m) => m.id == medicationId);
        if (medIndex != -1) {
          final med = meds[medIndex];
          if (med.remainingQuantity != null) {
            final dosageValue = double.tryParse(med.dosagePerIntake.split(' ').first) ?? 1.0;
            final updatedMed = med.copyWith(
              remainingQuantity: (med.remainingQuantity! - dosageValue).toInt().clamp(0, 9999),
            );
            await _repository.updateMedication(updatedMed);
            await loadMedications();
          }
        }
      }
    } catch (e) {
      debugPrint('Error logging dose: $e');
    }
  }

  Future<void> toggleMedication(String id, bool isEnabled) async {
    try {
      await _repository.toggleMedication(id, isEnabled);
      if (mounted) {
        final currentData = state.value ?? [];
        final med = currentData.firstWhere((m) => m.id == id);
        
        if (isEnabled) {
          _notificationService.scheduleMedicationNotifications(med);
        } else {
          _notificationService.cancelMedicationNotifications(med);
        }

        state = AsyncValue.data(
          currentData.map((m) => m.id == id ? m.copyWith(isEnabled: isEnabled) : m).toList(),
        );
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      final med = state.value?.firstWhere((m) => m.id == id);
      if (med != null) {
        _notificationService.cancelMedicationNotifications(med);
      }
      
      await _repository.deleteMedication(id);
      if (mounted) {
        final currentData = state.value ?? [];
        state = AsyncValue.data(currentData.where((m) => m.id != id).toList());
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> checkMissedDoses(List<Medication> meds) async {
    if (_userId == null) return;
    final logs = await _repository.getTodaysLogs(_userId!);
    final now = DateTime.now();
    int missedCount = 0;

    for (final med in meds.where((m) => m.isEnabled)) {
      for (final time in med.scheduledTimes) {
        final scheduledFor = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        
        // If dose was scheduled > 1 hour ago
        if (scheduledFor.isBefore(now.subtract(const Duration(hours: 1)))) {
          final isLogged = logs.any((l) => 
            l.medicationId == med.id && 
            l.scheduledFor.hour == scheduledFor.hour && 
            l.scheduledFor.minute == scheduledFor.minute
          );
          
          if (!isLogged) {
            missedCount++;
          }
        }
      }
    }

    if (missedCount >= 3) {
      _notificationService.showWarning(
        'Consistent Doses Missed', 
        'You have missed $missedCount doses recently. Repeated missed doses can affect treatment. Consider consulting a healthcare professional.'
      );

      // Part 3: Third-Party Integration Logic
      // If we have an emergency contact, send them a WhatsApp alert
      if (_profile != null && _profile!.emergencyContactPhone != null && _profile!.emergencyContactPhone!.isNotEmpty) {
        _messagingService.sendEmergencyAlert(
          recipientPhone: _profile!.emergencyContactPhone!,
          patientName: _profile!.username ?? 'Your patient',
          missedCount: missedCount,
          lastMedication: meds.first.name,
          channel: _profile!.preferredAlertChannel ?? 'WhatsApp',
          facebookId: _profile!.facebookId,
          instagramId: _profile!.instagramId,
        );
      }
    }
  }
}

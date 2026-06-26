import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/features/auth/presentation/auth_controller.dart';
import 'package:sharoni/features/profile/data/profile_repository.dart';
import 'package:sharoni/core/models/profile.dart';
import 'package:sharoni/features/symptoms/presentation/symptom_controller.dart';
import 'package:sharoni/features/medication/presentation/medication_controller.dart';

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<Profile?>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final userId = user?.id;
  return ProfileController(ref.watch(profileRepositoryProvider), userId, ref);
});

class ProfileController extends StateNotifier<AsyncValue<Profile?>> {
  final ProfileRepository _repository;
  final String? _userId;
  final Ref _ref;

  ProfileController(this._repository, this._userId, this._ref) : super(const AsyncValue.loading()) {
    if (_userId != null && _userId!.isNotEmpty) {
      loadProfile();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadProfile() async {
    if (_userId == null || _userId!.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile(_userId!);
      if (mounted) {
        state = AsyncValue.data(profile);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateProfile({
    String? username,
    String? age,
    String? height,
    String? weight,
    String? sex,
    String? bloodType,
    String? genotype,
    String? medicalConditions,
    String? allergies,
    String? currentMedications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? measurementUnit,
    bool? notifSound,
    bool? notifVibrate,
    bool? criticalAlerts,
    bool? escalationEnabled,
    bool? dailyDigestEnabled,
  }) async {
    if (_userId == null) return;
    
    final currentProfile = state.value;
    final updatedProfile = Profile(
      id: _userId!,
      username: username ?? currentProfile?.username,
      age: age ?? currentProfile?.age,
      height: height ?? currentProfile?.height,
      weight: weight ?? currentProfile?.weight,
      sex: sex ?? currentProfile?.sex,
      bloodType: bloodType ?? currentProfile?.bloodType,
      genotype: genotype ?? currentProfile?.genotype,
      medicalConditions: medicalConditions ?? currentProfile?.medicalConditions,
      allergies: allergies ?? currentProfile?.allergies,
      currentMedications: currentMedications ?? currentProfile?.currentMedications,
      emergencyContactName: emergencyContactName ?? currentProfile?.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? currentProfile?.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? currentProfile?.emergencyContactRelationship,
      measurementUnit: measurementUnit ?? currentProfile?.measurementUnit ?? 'metric',
      notifSound: notifSound ?? currentProfile?.notifSound ?? true,
      notifVibrate: notifVibrate ?? currentProfile?.notifVibrate ?? true,
      criticalAlerts: criticalAlerts ?? currentProfile?.criticalAlerts ?? false,
      escalationEnabled: escalationEnabled ?? currentProfile?.escalationEnabled ?? true,
      dailyDigestEnabled: dailyDigestEnabled ?? currentProfile?.dailyDigestEnabled ?? false,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.updateProfile(updatedProfile);
      if (mounted) {
        state = AsyncValue.data(updatedProfile);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updatePassword(String newPassword) async {
    // Supabase Auth handles password updates
    await _repository.updatePassword(newPassword);
  }

  Future<void> resetPassword(String email) async {
    await _repository.resetPassword(email);
  }

  Future<Map<String, dynamic>> exportAllData() async {
    if (_userId == null) throw Exception('User not authenticated');
    
    final profile = state.value;
    final symptoms = _ref.read(symptomControllerProvider).value ?? [];
    final medications = _ref.read(medicationControllerProvider).value ?? [];

    return {
      'exported_at': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'symptoms': symptoms.map((s) => s.toJson()).toList(),
      'medications': medications.map((m) => m.toJson()).toList(),
    };
  }
}

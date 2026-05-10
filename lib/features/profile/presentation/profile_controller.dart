import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/features/auth/presentation/auth_controller.dart';
import 'package:sharoni/features/profile/data/profile_repository.dart';
import 'package:sharoni/core/models/profile.dart';

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<Profile?>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final userId = user?.id;
  return ProfileController(ref.watch(profileRepositoryProvider), userId);
});

class ProfileController extends StateNotifier<AsyncValue<Profile?>> {
  final ProfileRepository _repository;
  final String? _userId;

  ProfileController(this._repository, this._userId) : super(const AsyncValue.loading()) {
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
    String? preferredAlertChannel,
    String? facebookId,
    String? instagramId,
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
      preferredAlertChannel: preferredAlertChannel ?? currentProfile?.preferredAlertChannel,
      facebookId: facebookId ?? currentProfile?.facebookId,
      instagramId: instagramId ?? currentProfile?.instagramId,
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
}

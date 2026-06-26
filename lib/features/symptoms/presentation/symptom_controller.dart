import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/features/auth/presentation/auth_controller.dart';
import 'package:sharoni/features/symptoms/data/symptom_repository.dart';
import 'package:sharoni/features/symptoms/data/ai_service.dart';
import 'package:sharoni/features/profile/presentation/profile_controller.dart';
import 'package:sharoni/core/models/profile.dart';
import 'package:sharoni/core/models/symptom.dart';

final symptomControllerProvider = StateNotifierProvider<SymptomController, AsyncValue<List<Symptom>>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final profile = ref.watch(profileControllerProvider).value;
  final userId = user?.id;
  return SymptomController(
    ref.watch(symptomRepositoryProvider),
    ref.watch(aiServiceProvider),
    userId,
    profile,
  );
});

class SymptomController extends StateNotifier<AsyncValue<List<Symptom>>> {
  final SymptomRepository _repository;
  final AIService _aiService;
  final String? _userId;
  final Profile? _profile;
  String? _selectedTag;

  SymptomController(this._repository, this._aiService, this._userId, this._profile) : super(const AsyncValue.loading()) {
    if (_userId != null && _userId!.isNotEmpty) {
      loadSymptoms();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  String? get selectedTag => _selectedTag;

  void filterByTag(String? tag) {
    _selectedTag = tag;
    loadSymptoms();
  }

  Future<void> loadSymptoms() async {
    if (_userId == null || _userId!.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      var symptoms = await _repository.getSymptoms(_userId!);
      
      // Client-side filtering for better performance
      if (_selectedTag != null) {
        symptoms = symptoms.where((s) => s.tags.contains(_selectedTag)).toList();
      }

      if (mounted) {
        state = AsyncValue.data(symptoms);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<Symptom> analyzeAndSaveSymptom(String description, {List<String> manualTags = const []}) async {
    if (_userId == null) throw Exception('User not logged in');
    
    final analysis = await _aiService.analyzeSymptoms(description, _profile);
    
    // Combine AI tags with manual user tags, ensuring no duplicates
    final combinedTags = <String>{...analysis.symptoms, ...manualTags}.toList();

    final symptom = Symptom(
      id: '', 
      userId: _userId!,
      description: description,
      analysisResult: analysis.advice,
      possibleCauses: analysis.possibleCauses,
      firstAid: analysis.firstAid,
      followUpLogic: analysis.followUpLogic,
      followUpQuestions: analysis.followUpQuestions,
      tags: combinedTags, 
      createdAt: DateTime.now(),
    );

    final savedSymptom = await _repository.addSymptom(symptom);
    await loadSymptoms();
    
    return savedSymptom;
  }
  
  // ... rest of methods remain ...

  Future<Symptom> refineAndSaveSymptom(String originalId, String originalDescription, List<String> questions, List<String> answers) async {
    if (_userId == null) throw Exception('User not logged in');
    
    // 1. Refine Analysis with AI
    final analysis = await _aiService.refineAnalysis(originalDescription, questions, answers, _profile);
    
    // 2. Append new questions if any
    final updatedQuestions = List<String>.from(questions);
    if (analysis.followUpQuestions.isNotEmpty) {
      updatedQuestions.addAll(analysis.followUpQuestions);
    }
    
    final symptom = Symptom(
      id: originalId,
      userId: _userId!,
      description: originalDescription,
      analysisResult: analysis.advice,
      possibleCauses: analysis.possibleCauses,
      firstAid: analysis.firstAid,
      followUpLogic: analysis.followUpLogic,
      followUpQuestions: updatedQuestions,
      followUpAnswers: answers,
      tags: analysis.symptoms,
      createdAt: DateTime.now(),
    );
    
    await _repository.updateSymptom(symptom);
    await loadSymptoms();
    
    return symptom;
  }

  Future<void> deleteSymptom(String id) async {
    try {
      await _repository.deleteSymptom(id);
      await loadSymptoms();
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

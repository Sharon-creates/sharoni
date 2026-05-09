import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/models/symptom.dart';

final symptomRepositoryProvider = Provider((ref) => SymptomRepository(Supabase.instance.client));

class SymptomRepository {
  final SupabaseClient _supabase;

  SymptomRepository(this._supabase);

  Future<List<Symptom>> getSymptoms(String userId) async {
    final response = await _supabase
        .from('symptoms')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Symptom.fromJson(json)).toList();
  }

  Future<Symptom> addSymptom(Symptom symptom) async {
    final response = await _supabase.from('symptoms').insert(symptom.toJson()).select().single();
    return Symptom.fromJson(response);
  }

  Future<void> updateSymptom(Symptom symptom) async {
    await _supabase.from('symptoms').update(symptom.toJson()).eq('id', symptom.id);
  }

  Future<void> deleteSymptom(String id) async {
    await _supabase.from('symptoms').delete().eq('id', id);
  }
}

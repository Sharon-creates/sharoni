import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:sharoni/core/models/medication.dart';
import 'package:sharoni/core/models/medication_log.dart';

final medicationRepositoryProvider = Provider((ref) => MedicationRepository(Supabase.instance.client));

class MedicationRepository {
  final SupabaseClient _supabase;

  MedicationRepository(this._supabase);

  Future<List<Medication>> getMedications(String userId) async {
    final response = await _supabase
        .from('medications')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    
    return (response as List).map((json) => Medication.fromJson(json)).toList();
  }

  Future<void> addMedication(Medication medication) async {
    await _supabase.from('medications').insert(medication.toJson());
  }

  Future<void> updateMedication(Medication medication) async {
    await _supabase
        .from('medications')
        .update(medication.toJson())
        .eq('id', medication.id);
  }

  Future<void> deleteMedication(String id) async {
    await _supabase.from('medications').delete().eq('id', id);
  }

  Future<List<String>> searchDrugs(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await _supabase
          .from('drug_dictionary')
          .select('drug_name')
          .ilike('drug_name', '$query%')
          .limit(10);
      
      return (response as List).map((row) => row['drug_name'] as String).toList();
    } catch (e) {
      debugPrint('Error searching drug dictionary, using fallback: $e');
      final fallbacks = [
        'Paracetamol',
        'Panadol',
        'Aspirin',
        'Ibuprofen',
        'Amoxicillin',
        'Metformin',
        'Atorvastatin',
        'Lisinopril',
        'Albuterol',
        'Omeprazole',
        'Penicillin',
        'Insulin'
      ];
      return fallbacks
          .where((d) => d.toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    }
  }

  Future<void> toggleMedication(String id, bool isEnabled) async {
    await _supabase
        .from('medications')
        .update({'is_enabled': isEnabled})
        .eq('id', id);
  }

  // Medication Logs
  Future<void> logMedicationDose(MedicationLog log) async {
    await _supabase.from('medication_logs').insert(log.toJson());
  }

  Future<List<MedicationLog>> getTodaysLogs(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

      final response = await _supabase
          .from('medication_logs')
          .select()
          .eq('user_id', userId)
          .gte('scheduled_for', startOfDay)
          .lte('scheduled_for', endOfDay);
      
      final List logs = response as List;
      return logs.map((json) => MedicationLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching today\'s logs: $e');
      return []; // Return empty instead of throwing to prevent UI crash
    }
  }
}


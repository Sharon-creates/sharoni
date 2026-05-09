import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/models/profile.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository(Supabase.instance.client));

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<Profile?> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      await _supabase.from('profiles').upsert(profile.toJson());
    } catch (e) {
      // If upsert fails, try a direct insert then update
      try {
        await _supabase.from('profiles').insert(profile.toJson());
      } catch (_) {
        await _supabase.from('profiles').update(profile.toJson()).eq('id', profile.id);
      }
    }
  }
}

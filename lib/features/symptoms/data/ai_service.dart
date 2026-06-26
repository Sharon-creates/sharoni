import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/models/profile.dart';
import 'package:sharoni/core/models/symptom.dart';
import 'package:flutter/foundation.dart';

final aiServiceProvider = Provider((ref) => AIService());

class AIService {
  // The middleman backend URL. On native builds this would be a deployed URL;
  // for local development and web we hit localhost.
  static const String _backendUrl = 'http://localhost:3000/analyze';

  Future<SymptomAnalysis> analyzeSymptoms(String description, [Profile? profile]) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _parseMiddlemanResponse(data, description);
      } else {
        debugPrint('Backend Error: ${response.statusCode}');
        return _generateFallbackAnalysis(description);
      }
    } catch (e) {
      debugPrint('Backend Request Exception: $e');
      return _generateFallbackAnalysis(description);
    }
  }

  Future<SymptomAnalysis> refineAnalysis(String originalDescription, List<String> questions, List<String> answers, [Profile? profile]) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': originalDescription,
          'questions': questions,
          'answers': answers,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _parseMiddlemanResponse(data, originalDescription);
      } else {
        debugPrint('Backend Error: ${response.statusCode}');
        return _generateFallbackAnalysis(originalDescription);
      }
    } catch (e) {
      debugPrint('Backend Request Exception: $e');
      return _generateFallbackAnalysis(originalDescription);
    }
  }

  SymptomAnalysis _parseMiddlemanResponse(Map<String, dynamic> data, String description) {
    if (data['status'] == 'need_more_info') {
      return SymptomAnalysis(
        symptoms: [],
        possibleCauses: null,
        firstAid: null,
        advice: 'Please answer the follow-up question to refine your analysis.',
        followUpQuestions: [data['question'].toString()],
      );
    }

    return SymptomAnalysis(
      symptoms: List<String>.from(data['symptoms'] ?? []),
      possibleCauses: data['possible_causes'] ?? 'Requires further clinical evaluation.',
      firstAid: data['first_aid'] ?? 'Rest and monitor symptoms.',
      advice: data['advice'] ?? 'Monitor your condition closely.',
      followUpQuestions: [],
    );
  }

  SymptomAnalysis _generateFallbackAnalysis(String description) {
    final lowerDesc = description.toLowerCase();
    final symptoms = _extractSymptomsFallback(description);
    
    if (lowerDesc.contains('headache')) {
      return SymptomAnalysis(
        symptoms: symptoms,
        possibleCauses: "Stress, dehydration, lack of sleep, or tension.",
        firstAid: "1. Rest in a quiet, dark room.\n2. Stay hydrated.\n3. Consider mild pain relief.",
        advice: "It sounds like a tension headache. Monitor for any worsening.",
        followUpQuestions: [],
      );
    } else if (lowerDesc.contains('fever') || lowerDesc.contains('cold')) {
      return SymptomAnalysis(
        symptoms: symptoms,
        possibleCauses: "Viral infection (common cold or flu), or inflammatory response.",
        firstAid: "1. Monitor temperature.\n2. Rest and stay warm.\n3. Drink plenty of fluids.",
        advice: "Common cold/fever symptoms detected. Stay hydrated.",
        followUpQuestions: [],
      );
    } else if (lowerDesc.contains('stomach') || lowerDesc.contains('nausea')) {
      return SymptomAnalysis(
        symptoms: symptoms,
        possibleCauses: "Indigestion, food sensitivity, or mild gastritis.",
        firstAid: "1. Rest your stomach (sip water).\n2. Avoid heavy meals.\n3. Try ginger tea.",
        advice: "Abdominal discomfort noted. Monitor for sharp pain.",
        followUpQuestions: [],
      );
    }
    
    return SymptomAnalysis(
      symptoms: symptoms,
      possibleCauses: "[OFFLINE MODE] Requires further professional evaluation.",
      firstAid: "Rest and observe symptoms for any new developments.",
      advice: "Your symptoms have been logged in offline mode. Please consult a healthcare provider for a professional diagnosis.",
      followUpQuestions: [],
    );
  }

  List<String> _extractSymptomsFallback(String description) {
    final commonSymptoms = ['cold', 'cough', 'catarrh', 'fever', 'headache', 'nausea', 'fatigue', 'pain', 'sore throat'];
    final lower = description.toLowerCase();
    return commonSymptoms.where((s) => lower.contains(s)).toList();
  }
}

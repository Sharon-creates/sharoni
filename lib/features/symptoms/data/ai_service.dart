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
        throw Exception('AI analysis failed. Backend returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Backend Request Exception: $e');
      throw Exception('Unable to connect to the AI service. Please ensure the backend server is running on port 3000. (Details: $e)');
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
        throw Exception('AI refine analysis failed. Backend returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Backend Request Exception: $e');
      throw Exception('Unable to connect to the AI service to refine analysis. (Details: $e)');
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
}

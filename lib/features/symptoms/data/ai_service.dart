import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/models/profile.dart';

final aiServiceProvider = Provider((ref) => AIService());

class SymptomAnalysis {
  final List<String> symptoms;
  final String? possibleCauses;
  final String? firstAid;
  final String advice; // General advice/summary
  final List<String> followUpQuestions;

  SymptomAnalysis({
    required this.symptoms, 
    this.possibleCauses, 
    this.firstAid, 
    required this.advice,
    this.followUpQuestions = const [],
  });
}


class AIService {
  // Normally you would use an environment variable or a secure vault
  final String _apiKey = 'hf_your_api_key_placeholder'; 
  final String _modelUrl = 'https://api-inference.huggingface.co/models/google/flan-t5-base';

  Future<SymptomAnalysis> analyzeSymptoms(String description, [Profile? profile]) async {
    return _analyzeInternal(description, profile: profile);
  }

  Future<SymptomAnalysis> refineAnalysis(String originalDescription, List<String> questions, List<String> answers, [Profile? profile]) async {
    final refinedDescription = "Original: $originalDescription. " + 
        List.generate(questions.length, (i) => "Q: ${questions[i]} A: ${i < answers.length ? answers[i] : 'N/A'}").join(". ");
    
    return _analyzeInternal(refinedDescription, profile: profile, isRefined: true);
  }

  Future<SymptomAnalysis> _analyzeInternal(String description, {Profile? profile, bool isRefined = false}) async {
    try {
      String contextString = "";
      if (profile != null) {
        final contextParts = <String>[];
        if (profile.age != null) contextParts.add("Age: ${profile.age}");
        if (profile.sex != null) contextParts.add("Sex: ${profile.sex}");
        if (profile.medicalConditions != null && profile.medicalConditions!.isNotEmpty) {
          contextParts.add("Known conditions: ${profile.medicalConditions}");
        }
        if (profile.allergies != null && profile.allergies!.isNotEmpty) {
          contextParts.add("Allergies: ${profile.allergies}");
        }
        if (contextParts.isNotEmpty) {
          contextString = "User Background context: (${contextParts.join(', ')}). ";
        }
      }

      final prompt = isRefined 
          ? "Act as a clinical triage assistant. Perform a multi-step analysis. "
            "USER DATA INPUT: "
            "- Primary Symptom: ${_extractPrimarySymptom(description)} "
            "- Onset (When noticed): ${description.contains('A:') ? _extractAnswer(description, 0) : 'Not provided'} "
            "- Triggers (Better/Worse): ${description.contains('A:') ? _extractAnswer(description, 1) : 'Not provided'} "
            "ANALYSIS LOGIC: "
            "1. CROSS-REFERENCE: Look at how Onset and Triggers change the nature of the Primary Symptom. "
            "2. TRIAGE CATEGORIZATION: Determine if it indicates Emergency, Urgent Care, or Home Care. "
            "3. FIRST AID DERIVATION: Suggest immediate comfort measures. "
            "EXPECTED OUTPUT FORMAT (JSON): "
            "{ \"possible_causes\": \"...\", \"first_aid_opinion\": \"...\", \"advice\": \"...\", \"follow_up_logic\": \"...\" } "
            "CONSTRAINTS: Calm clinical tone, safety-first, no definitive diagnosis."
          : "As a medical assistant, analyze this: '$description'. ${contextString}"
            "1. Extract symptoms (comma list). 2. Possible causes. 3. First-aid. 4. If brief, 2-3 questions. "
            "Format: 'Symptoms: [symptoms], Causes: [causes], First Aid: [first_aid], Questions: [q1|q2|q3], Advice: [summary]'.";
      
      final response = await http.post(

        Uri.parse(_modelUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_new_tokens': 500,
            'temperature': 0.3,
          },
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final String generatedText = data[0]['generated_text'];
        
        if (isRefined) {
          return _parseJSONResponse(generatedText, description);
        } else {
          return _parseAIResponse(generatedText, description);
        }
      }
      
      return _generateFallbackAnalysis(description);
    } catch (e) {
      return _generateFallbackAnalysis(description);
    }
  }

  String _extractPrimarySymptom(String description) {
    if (description.contains('Original:')) {
      final parts = description.split('Original:');
      if (parts.length > 1) {
        return parts[1].split('.')[0].trim();
      }
    }
    return description;
  }

  String _extractAnswer(String description, int index) {
    final matches = RegExp(r'A: (.*?)(?=\. Q:|\.|$)').allMatches(description).map((m) => m.group(1) ?? '').toList();
    if (index < matches.length) return matches[index];
    return 'Not provided';
  }

  SymptomAnalysis _parseJSONResponse(String text, String originalDescription) {
    try {
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr);
        
        return SymptomAnalysis(
          symptoms: _extractSymptomsFallback(originalDescription),
          possibleCauses: data['possible_causes'] ?? "Undetermined.",
          firstAid: data['first_aid_opinion'] ?? "Rest and monitor.",
          advice: data['advice'] ?? "Monitor your condition.",
          followUpLogic: data['follow_up_logic'],
        );
      }
    } catch (_) {}
    return _parseAIResponse(text, originalDescription);
  }

  SymptomAnalysis _parseAIResponse(String text, String originalDescription) {
    try {
      final symptoms = _extractPart(text, 'Symptoms:', 'Causes:');
      final causes = _extractPart(text, 'Causes:', 'First Aid:');
      final firstAid = _extractPart(text, 'First Aid:', 'Questions:');
      final questions = _extractPart(text, 'Questions:', 'Advice:');
      final advice = _extractPart(text, 'Advice:', '');

      final symptomsList = symptoms.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
      final questionsList = questions.split('|').map((q) => q.trim()).where((q) => q.isNotEmpty).toList();
      
      return SymptomAnalysis(
        symptoms: symptomsList.isNotEmpty ? symptomsList : _extractSymptomsFallback(originalDescription),
        possibleCauses: causes.isNotEmpty ? causes : "Unable to determine specific causes.",
        firstAid: firstAid.isNotEmpty ? firstAid : "Rest and stay hydrated. Consult a doctor if symptoms persist.",
        advice: advice.isNotEmpty ? advice : "Please monitor your condition.",
        followUpQuestions: questionsList,
      );
    } catch (_) {
      return _generateFallbackAnalysis(originalDescription);
    }
  }

  String _extractPart(String text, String start, String end) {
    if (!text.contains(start)) return "";
    final startIndex = text.indexOf(start) + start.length;
    final endIndex = end.isNotEmpty && text.contains(end) ? text.indexOf(end) : text.length;
    if (startIndex >= endIndex) return "";
    return text.substring(startIndex, endIndex).trim();
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
        followUpQuestions: [
          "Where exactly is the pain located?",
          "Is the pain sharp, dull, or throbbing?",
          "Are you experiencing any light sensitivity or nausea?"
        ],
      );
    } else if (lowerDesc.contains('fever') || lowerDesc.contains('cold')) {
      return SymptomAnalysis(
        symptoms: symptoms,
        possibleCauses: "Viral infection (common cold or flu), or inflammatory response.",
        firstAid: "1. Monitor temperature.\n2. Rest and stay warm.\n3. Drink plenty of fluids.",
        advice: "Common cold/fever symptoms detected. Stay hydrated.",
        followUpQuestions: [
          "What is your current body temperature?",
          "Do you have a cough or sore throat?",
          "How long have you been feeling this way?"
        ],
      );
    } else if (lowerDesc.contains('stomach') || lowerDesc.contains('nausea')) {
      return SymptomAnalysis(
        symptoms: symptoms,
        possibleCauses: "Indigestion, food sensitivity, or mild gastritis.",
        firstAid: "1. Rest your stomach (sip water).\n2. Avoid heavy meals.\n3. Try ginger tea.",
        advice: "Abdominal discomfort noted. Monitor for sharp pain.",
        followUpQuestions: [
          "When did the pain start relative to your last meal?",
          "Is there any bloating or heartburn?",
          "Have you had similar pain before?"
        ],
      );
    }
    
    return SymptomAnalysis(
      symptoms: symptoms,
      possibleCauses: "Requires further professional evaluation.",
      firstAid: "Rest and observe symptoms for any new developments.",
      advice: "Your symptoms have been logged. Please consult a healthcare provider for a professional diagnosis.",
      followUpQuestions: [
        "When did you first notice this?",
        "Does anything make it better or worse?",
        "Are you taking any new medications?"
      ],
    );
  }



  List<String> _extractSymptomsFallback(String description) {
    final commonSymptoms = ['cold', 'cough', 'catarrh', 'fever', 'headache', 'nausea', 'fatigue', 'pain', 'sore throat'];
    final lower = description.toLowerCase();
    return commonSymptoms.where((s) => lower.contains(s)).toList();
  }
}

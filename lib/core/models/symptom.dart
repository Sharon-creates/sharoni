class SymptomAnalysis {
  final List<String> symptoms;
  final String? possibleCauses;
  final String? firstAid;
  final String advice; 
  final String? followUpLogic;
  final List<String> followUpQuestions;

  SymptomAnalysis({
    required this.symptoms, 
    this.possibleCauses, 
    this.firstAid, 
    required this.advice,
    this.followUpLogic,
    this.followUpQuestions = const [],
  });
}

class Symptom {
  final String id;
  final String userId;
  final String description;
  final String? analysisResult; // Legacy field
  final String? possibleCauses;
  final String? firstAid;
  final String? followUpLogic;
  final List<String> tags;
  final List<String> followUpQuestions;
  final List<String> followUpAnswers;
  final DateTime createdAt;

  Symptom({
    required this.id,
    required this.userId,
    required this.description,
    this.analysisResult,
    this.possibleCauses,
    this.firstAid,
    this.followUpLogic,
    List<String>? tags,
    List<String>? followUpQuestions,
    List<String>? followUpAnswers,
    required this.createdAt,
  }) : this.tags = tags ?? const [],
       this.followUpQuestions = followUpQuestions ?? const [],
       this.followUpAnswers = followUpAnswers ?? const [];

  factory Symptom.fromJson(Map<String, dynamic> json) {
    // Helper to safely extract lists of strings
    List<String> safeList(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    return Symptom(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      analysisResult: json['analysis_result']?.toString(),
      possibleCauses: json['possible_causes']?.toString(),
      firstAid: json['first_aid']?.toString(),
      followUpLogic: json['follow_up_logic']?.toString(),
      tags: safeList(json['tags'] ?? json['tags_list']),
      followUpQuestions: safeList(json['follow_up_questions'] ?? json['followUpQuestions']),
      followUpAnswers: safeList(json['follow_up_answers'] ?? json['followUpAnswers']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'description': description,
      'analysis_result': analysisResult,
      'possible_causes': possibleCauses,
      'first_aid': firstAid,
      'follow_up_logic': followUpLogic,
      'tags': tags,
      'follow_up_questions': followUpQuestions,
      'follow_up_answers': followUpAnswers,
      'created_at': createdAt.toIso8601String(),
    };

    
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    
    return data;
  }
}




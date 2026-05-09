class Profile {
  final String id;
  final String? username;
  final String? age;
  final String? height;
  final String? weight;
  final String? sex;
  final String? bloodType;
  final String? medicalConditions;
  final String? allergies;
  final String? currentMedications;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.username,
    this.age,
    this.height,
    this.weight,
    this.sex,
    this.bloodType,
    this.medicalConditions,
    this.allergies,
    this.currentMedications,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      age: json['age'],
      height: json['height'],
      weight: json['weight'],
      sex: json['sex'],
      bloodType: json['blood_type'],
      medicalConditions: json['medical_conditions'],
      allergies: json['allergies'],
      currentMedications: json['current_medications'],
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'age': age,
      'height': height,
      'weight': weight,
      'sex': sex,
      'blood_type': bloodType,
      'medical_conditions': medicalConditions,
      'allergies': allergies,
      'current_medications': currentMedications,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? username,
    String? age,
    String? height,
    String? weight,
    String? sex,
    String? bloodType,
    String? medicalConditions,
    String? allergies,
    String? currentMedications,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      sex: sex ?? this.sex,
      bloodType: bloodType ?? this.bloodType,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

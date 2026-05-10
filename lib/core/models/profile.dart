class Profile {
  final String id;
  final String? username;
  final String? age;
  final String? height;
  final String? weight;
  final String? sex;
  final String? bloodType;
  final String? genotype;
  final String? medicalConditions;
  final String? allergies;
  final String? currentMedications;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? preferredAlertChannel; 
  final String? facebookId;
  final String? instagramId;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.username,
    this.age,
    this.height,
    this.weight,
    this.sex,
    this.bloodType,
    this.genotype,
    this.medicalConditions,
    this.allergies,
    this.currentMedications,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.preferredAlertChannel,
    this.facebookId,
    this.instagramId,
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
      genotype: json['genotype'],
      medicalConditions: json['medical_conditions'],
      allergies: json['allergies'],
      currentMedications: json['current_medications'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      preferredAlertChannel: json['preferred_alert_channel'],
      facebookId: json['facebook_id'],
      instagramId: json['instagram_id'],
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
      'genotype': genotype,
      'medical_conditions': medicalConditions,
      'allergies': allergies,
      'current_medications': currentMedications,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relationship': emergencyContactRelationship,
      'preferred_alert_channel': preferredAlertChannel,
      'facebook_id': facebookId,
      'instagram_id': instagramId,
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
      genotype: genotype ?? this.genotype,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      preferredAlertChannel: preferredAlertChannel ?? this.preferredAlertChannel,
      facebookId: facebookId ?? this.facebookId,
      instagramId: instagramId ?? this.instagramId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

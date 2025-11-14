class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final String? avatarUrl;
  
  // Thông tin cá nhân
  final int? age;
  final String? gender; // 'male', 'female', 'other'
  final double? height; // Chiều cao (cm)
  final double? targetWeight; // Cân nặng mục tiêu (kg)
  
  // Thông tin y tế
  final String? medicalHistory; // Tiền sử bệnh lý
  final String? currentMedications; // Thuốc đang dùng
  final String? allergies; // Dị ứng
  
  // Cài đặt
  final bool biometricEnabled;
  final String? preferredLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.avatarUrl,
    this.age,
    this.gender,
    this.height,
    this.targetWeight,
    this.medicalHistory,
    this.currentMedications,
    this.allergies,
    this.biometricEnabled = false,
    this.preferredLanguage,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
        'age': age,
        'gender': gender,
        'height': height,
        'targetWeight': targetWeight,
        'medicalHistory': medicalHistory,
        'currentMedications': currentMedications,
        'allergies': allergies,
        'biometricEnabled': biometricEnabled,
        'preferredLanguage': preferredLanguage,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String,
        email: map['email'] as String,
        name: map['name'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        age: map['age']?.toInt(),
        gender: map['gender'] as String?,
        height: map['height']?.toDouble(),
        targetWeight: map['targetWeight']?.toDouble(),
        medicalHistory: map['medicalHistory'] as String?,
        currentMedications: map['currentMedications'] as String?,
        allergies: map['allergies'] as String?,
        biometricEnabled: map['biometricEnabled'] ?? false,
        preferredLanguage: map['preferredLanguage'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : null,
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'])
            : null,
      );

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    int? age,
    String? gender,
    double? height,
    double? targetWeight,
    String? medicalHistory,
    String? currentMedications,
    String? allergies,
    bool? biometricEnabled,
    String? preferredLanguage,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      currentMedications: currentMedications ?? this.currentMedications,
      allergies: allergies ?? this.allergies,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}


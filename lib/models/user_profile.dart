class UserInfo {
  final String id;
  final String fullName;
  final String? preferredName;
  final DateTime dateOfBirth;
  final String? phoneNumber;
  final String? bio;
  final String? currentLocationId;
  final bool isAvailable;
  final String status;
  final DateTime? lastActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? avatarUrl;
  final String accountStatus;
  final String visibility;
  final bool emailVerified;

  UserInfo({
    required this.id,
    required this.fullName,
    this.preferredName,
    required this.dateOfBirth,
    this.phoneNumber,
    this.bio,
    this.currentLocationId,
    required this.isAvailable,
    required this.status,
    this.lastActive,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    required this.accountStatus,
    required this.visibility,
    required this.emailVerified,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      fullName: json['full_name'],
      preferredName: json['preferred_name'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      phoneNumber: json['phone_number'],
      bio: json['bio'],
      currentLocationId: json['current_location_id'],
      isAvailable: json['is_available'] ?? true,
      status: json['status'] ?? 'Active',
      lastActive: json['last_active'] != null 
          ? DateTime.parse(json['last_active']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      avatarUrl: json['avatar_url'],
      accountStatus: json['account_status'] ?? 'active',
      visibility: json['visibility'] ?? 'public',
      emailVerified: json['email_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'preferred_name': preferredName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'phone_number': phoneNumber,
      'bio': bio,
      'current_location_id': currentLocationId,
      'is_available': isAvailable,
      'status': status,
      'avatar_url': avatarUrl,
      'account_status': accountStatus,
      'visibility': visibility,
    };
  }

  UserInfo copyWith({
    String? fullName,
    String? preferredName,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? bio,
    String? currentLocationId,
    bool? isAvailable,
    String? status,
    String? avatarUrl,
    String? accountStatus,
    String? visibility,
  }) {
    return UserInfo(
      id: id,
      fullName: fullName ?? this.fullName,
      preferredName: preferredName ?? this.preferredName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      lastActive: lastActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accountStatus: accountStatus ?? this.accountStatus,
      visibility: visibility ?? this.visibility,
      emailVerified: emailVerified,
    );
  }
}

class UserProfile {
  final String id;
  final String? pronouns;
  final String? sexuality;
  final List<String>? humorType;
  final List<String>? adventureStyle;
  final List<String>? activePursuits;
  final List<String>? socialEnergy;
  final List<String>? cultureConnect;
  final List<String>? valuesStyle;
  final bool showSexualityOnProfile;
  final bool shareInMatching;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.pronouns,
    this.sexuality,
    this.humorType,
    this.adventureStyle,
    this.activePursuits,
    this.socialEnergy,
    this.cultureConnect,
    this.valuesStyle,
    required this.showSexualityOnProfile,
    required this.shareInMatching,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      pronouns: json['pronouns'],
      sexuality: json['sexuality'],
      humorType: json['humor_type'] != null 
          ? List<String>.from(json['humor_type']) 
          : null,
      adventureStyle: json['adventure_style'] != null 
          ? List<String>.from(json['adventure_style']) 
          : null,
      activePursuits: json['active_pursuits'] != null 
          ? List<String>.from(json['active_pursuits']) 
          : null,
      socialEnergy: json['social_energy'] != null 
          ? List<String>.from(json['social_energy']) 
          : null,
      cultureConnect: json['culture_connect'] != null 
          ? List<String>.from(json['culture_connect']) 
          : null,
      valuesStyle: json['values_style'] != null 
          ? List<String>.from(json['values_style']) 
          : null,
      showSexualityOnProfile: json['show_sexuality_on_profile'] ?? true,
      shareInMatching: json['share_in_matching'] ?? true,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pronouns': pronouns,
      'sexuality': sexuality,
      'humor_type': humorType,
      'adventure_style': adventureStyle,
      'active_pursuits': activePursuits,
      'social_energy': socialEnergy,
      'culture_connect': cultureConnect,
      'values_style': valuesStyle,
      'show_sexuality_on_profile': showSexualityOnProfile,
      'share_in_matching': shareInMatching,
    };
  }

  UserProfile copyWith({
    String? pronouns,
    String? sexuality,
    List<String>? humorType,
    List<String>? adventureStyle,
    List<String>? activePursuits,
    List<String>? socialEnergy,
    List<String>? cultureConnect,
    List<String>? valuesStyle,
    bool? showSexualityOnProfile,
    bool? shareInMatching,
  }) {
    return UserProfile(
      id: id,
      pronouns: pronouns ?? this.pronouns,
      sexuality: sexuality ?? this.sexuality,
      humorType: humorType ?? this.humorType,
      adventureStyle: adventureStyle ?? this.adventureStyle,
      activePursuits: activePursuits ?? this.activePursuits,
      socialEnergy: socialEnergy ?? this.socialEnergy,
      cultureConnect: cultureConnect ?? this.cultureConnect,
      valuesStyle: valuesStyle ?? this.valuesStyle,
      showSexualityOnProfile: showSexualityOnProfile ?? this.showSexualityOnProfile,
      shareInMatching: shareInMatching ?? this.shareInMatching,
      updatedAt: DateTime.now(),
    );
  }
}

class UserLanguage {
  final String userId;
  final String languageId;
  final String languageName;
  final String proficiency;

  UserLanguage({
    required this.userId,
    required this.languageId,
    required this.languageName,
    required this.proficiency,
  });

  factory UserLanguage.fromJson(Map<String, dynamic> json) {
    return UserLanguage(
      userId: json['user_id'],
      languageId: json['language_id'],
      languageName: json['name'], // From joined languages table
      proficiency: json['proficiency'] ?? 'conversational',
    );
  }
}

class UserNationality {
  final String userId;
  final String countryId;
  final String countryName;
  final bool isPrimary;

  UserNationality({
    required this.userId,
    required this.countryId,
    required this.countryName,
    required this.isPrimary,
  });

  factory UserNationality.fromJson(Map<String, dynamic> json) {
    return UserNationality(
      userId: json['user_id'],
      countryId: json['country_id'],
      countryName: json['name'], // From joined countries table
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

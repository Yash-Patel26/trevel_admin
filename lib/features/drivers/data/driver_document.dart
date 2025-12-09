class DriverDocument {
  final int id;
  final String name;
  final String
      type; // 'pan', 'aadhar', 'driving_license', 'police_verification'
  final String? fileUrl; // URL or path to the uploaded document/image
  final DateTime uploadedAt;

  // Document-specific metadata
  // For PAN: number
  final String? panNumber;

  // For Aadhar: number
  final String? aadharNumber;

  // For Driving License: number, issuing authority, issued date, expiry date
  final String? licenseNumber;
  final String? issuingAuthority;
  final DateTime? issuedDate;
  final DateTime? expiryDate;

  // For Police Verification: no additional fields needed

  DriverDocument({
    required this.id,
    required this.name,
    required this.type,
    this.fileUrl,
    required this.uploadedAt,
    this.panNumber,
    this.aadharNumber,
    this.licenseNumber,
    this.issuingAuthority,
    this.issuedDate,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
      'panNumber': panNumber,
      'aadharNumber': aadharNumber,
      'licenseNumber': licenseNumber,
      'issuingAuthority': issuingAuthority,
      'issuedDate': issuedDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      fileUrl: json['fileUrl'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      panNumber: json['panNumber'] as String?,
      aadharNumber: json['aadharNumber'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      issuingAuthority: json['issuingAuthority'] as String?,
      issuedDate: json['issuedDate'] != null
          ? DateTime.parse(json['issuedDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }

  DriverDocument copyWith({
    int? id,
    String? name,
    String? type,
    String? fileUrl,
    DateTime? uploadedAt,
    String? panNumber,
    String? aadharNumber,
    String? licenseNumber,
    String? issuingAuthority,
    DateTime? issuedDate,
    DateTime? expiryDate,
  }) {
    return DriverDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      panNumber: panNumber ?? this.panNumber,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      issuedDate: issuedDate ?? this.issuedDate,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

class ContactPreferences {
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final String? preferredContactMethod; // 'email', 'sms', 'phone'

  ContactPreferences({
    this.emailNotifications = true,
    this.smsNotifications = true,
    this.pushNotifications = true,
    this.preferredContactMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'pushNotifications': pushNotifications,
      'preferredContactMethod': preferredContactMethod,
    };
  }

  factory ContactPreferences.fromJson(Map<String, dynamic> json) {
    return ContactPreferences(
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      smsNotifications: json['smsNotifications'] as bool? ?? true,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      preferredContactMethod: json['preferredContactMethod'] as String?,
    );
  }
}

class PricingConfig {
  final String id;
  final String serviceType;
  final Map<String, dynamic> config;
  final bool isActive;
  final DateTime updatedAt;

  PricingConfig({
    required this.id,
    required this.serviceType,
    required this.config,
    required this.isActive,
    required this.updatedAt,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      id: json['id'],
      serviceType: json['serviceType'] ?? json['service_type'],
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'config': config,
      'isActive': isActive,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

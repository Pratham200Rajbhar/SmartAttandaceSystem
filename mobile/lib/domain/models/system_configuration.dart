class SystemConfiguration {
  final bool isFaceRecognitionEnabled;
  final bool isGpsVerificationEnabled;
  final bool isAiBackgroundValidationEnabled;

  SystemConfiguration({
    required this.isFaceRecognitionEnabled,
    required this.isGpsVerificationEnabled,
    required this.isAiBackgroundValidationEnabled,
  });

  factory SystemConfiguration.fromJson(Map<String, dynamic> json) {
    return SystemConfiguration(
      isFaceRecognitionEnabled: json['isFaceRecognitionEnabled'] ?? true,
      isGpsVerificationEnabled: json['isGpsVerificationEnabled'] ?? true,
      isAiBackgroundValidationEnabled: json['isAiBackgroundValidationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFaceRecognitionEnabled': isFaceRecognitionEnabled,
      'isGpsVerificationEnabled': isGpsVerificationEnabled,
      'isAiBackgroundValidationEnabled': isAiBackgroundValidationEnabled,
    };
  }
}

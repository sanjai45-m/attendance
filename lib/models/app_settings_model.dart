class AppSettingsModel {
  final int lateThresholdMinutes;
  final String workStartTime;
  final String telegramBotToken;
  final String telegramChatId;
  final String fcmServerKey;

  AppSettingsModel({
    this.lateThresholdMinutes = 15,
    this.workStartTime = '09:00',
    this.telegramBotToken = '',
    this.telegramChatId = '',
    this.fcmServerKey = '',
  });

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      lateThresholdMinutes: map['lateThresholdMinutes'] ?? 15,
      workStartTime: map['workStartTime'] ?? '09:00',
      telegramBotToken: map['telegramBotToken'] ?? '',
      telegramChatId: map['telegramChatId'] ?? '',
      fcmServerKey: map['fcmServerKey'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lateThresholdMinutes': lateThresholdMinutes,
      'workStartTime': workStartTime,
      'telegramBotToken': telegramBotToken,
      'telegramChatId': telegramChatId,
      'fcmServerKey': fcmServerKey,
    };
  }

  bool get isTelegramConfigured =>
      telegramBotToken.isNotEmpty && telegramChatId.isNotEmpty;

  bool get isFcmConfigured => fcmServerKey.isNotEmpty;

  AppSettingsModel copyWith({
    int? lateThresholdMinutes,
    String? workStartTime,
    String? telegramBotToken,
    String? telegramChatId,
    String? fcmServerKey,
  }) {
    return AppSettingsModel(
      lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
      workStartTime: workStartTime ?? this.workStartTime,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      fcmServerKey: fcmServerKey ?? this.fcmServerKey,
    );
  }
}

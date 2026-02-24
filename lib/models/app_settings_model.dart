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
    final rawThreshold = map['lateThresholdMinutes'];
    final threshold = rawThreshold is int
        ? rawThreshold
        : (rawThreshold is String ? int.tryParse(rawThreshold) ?? 15 : 15);

    return AppSettingsModel(
      lateThresholdMinutes: threshold,
      workStartTime: map['workStartTime']?.toString() ?? '09:00',
      telegramBotToken: map['telegramBotToken']?.toString() ?? '',
      telegramChatId: map['telegramChatId']?.toString() ?? '',
      fcmServerKey: map['fcmServerKey']?.toString() ?? '',
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

import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramService {
  /// Send a message to Telegram
  Future<bool> sendMessage({
    required String botToken,
    required String chatId,
    required String message,
  }) async {
    if (botToken.isEmpty || chatId.isEmpty) return false;

    try {
      final url = Uri.parse(
        'https://api.telegram.org/bot$botToken/sendMessage',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      // Silently fail — Telegram is a nice-to-have, not critical
      return false;
    }
  }

  /// Format punch-in message
  String formatPunchInMessage({
    required String employeeName,
    required String employeeId,
    required String time,
  }) {
    return '✅ *$employeeName* ($employeeId) punched IN at $time';
  }

  /// Format punch-out message
  String formatPunchOutMessage({
    required String employeeName,
    required String employeeId,
    required String time,
    required String totalHours,
  }) {
    return '🔴 *$employeeName* ($employeeId) punched OUT at $time — Worked $totalHours';
  }
}

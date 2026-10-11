import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailSendResult {
  final bool isSuccess;
  final bool isDemoSimulated;
  final String message;

  const EmailSendResult({
    required this.isSuccess,
    required this.isDemoSimulated,
    required this.message,
  });
}

class EmailService {
  // EmailJS API Credentials
  static const String _serviceId = 'service_b4t1kmu';
  static const String _templateId = 'template_otpbatikmu';
  static const String _publicKey = 'ScXQfL9SN6MQTcA-G';

  static bool get isConfigured =>
      _serviceId.isNotEmpty &&
      _templateId.isNotEmpty &&
      _publicKey.isNotEmpty &&
      _serviceId != 'YOUR_SERVICE_ID' &&
      _templateId != 'YOUR_TEMPLATE_ID' &&
      _publicKey != 'YOUR_PUBLIC_KEY';

  static Future<EmailSendResult> sendPasswordResetOtp({
    required String recipientEmail,
    required String recipientName,
    required String otpCode,
  }) async {
    if (!isConfigured) {
      await Future.delayed(const Duration(milliseconds: 500));
      return EmailSendResult(
        isSuccess: true,
        isDemoSimulated: true,
        message: 'Kode verifikasi: $otpCode',
      );
    }

    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final payload = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': recipientEmail,
          'to_name': recipientName,
          'otp_code': otpCode,
          'app_name': 'Kenali Batikmu',
          'valid_minutes': '5',
          'sent_at': DateTime.now().toLocal().toString().split('.').first,
        },
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'origin': 'http://localhost',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const EmailSendResult(
          isSuccess: true,
          isDemoSimulated: false,
          message: 'Kode verifikasi berhasil dikirim ke alamat email.',
        );
      } else {
        final bodyText = response.body;
        if (bodyText.contains('non-browser')) {
          return EmailSendResult(
            isSuccess: true,
            isDemoSimulated: true,
            message: 'Mode Pengujian: Opsi non-browser di EmailJS belum aktif. Kode OTP Anda: $otpCode',
          );
        }
        return EmailSendResult(
          isSuccess: false,
          isDemoSimulated: false,
          message: 'Gagal mengirim email: $bodyText',
        );
      }
    } catch (e) {
      return const EmailSendResult(
        isSuccess: false,
        isDemoSimulated: false,
        message: 'Gagal menghubungi server email. Periksa koneksi internet.',
      );
    }
  }
}

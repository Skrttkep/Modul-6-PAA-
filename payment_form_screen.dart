import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carrental/config/api_config.dart';
import 'package:carrental/models/payment_model.dart';
import 'package:carrental/services/auth_service.dart';

class PaymentService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<PaymentModel> createPayment(PaymentModel payment) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.paymentsPrefix}',
    );

    final headers = await _authHeaders();

    final requestBody = payment.toJson();

    final response = await http
        .post(
          url,
          headers: headers,
          body: json.encode(_cleanBody(requestBody)),
        )
        .timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        throw Exception('Request pembayaran terlalu lama');
      },
    );

    final responseBody = _safeDecode(response.body);

    // Debug terminal
    // ignore: avoid_print
    print('PAYMENT REQUEST');
    // ignore: avoid_print
    print('URL: $url');
    // ignore: avoid_print
    print('BODY: ${json.encode(_cleanBody(requestBody))}');
    // ignore: avoid_print
    print('STATUS: ${response.statusCode}');
    // ignore: avoid_print
    print('RESPONSE: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parsePaymentResponse(responseBody, payment);
    }

    throw Exception(_extractErrorMessage(responseBody));
  }

  static String _extractErrorMessage(Map<String, dynamic> responseBody) {
    if (responseBody['errors'] is List) {
      final errors = responseBody['errors'] as List;

      return errors.map((item) {
        if (item is Map<String, dynamic>) {
          final field = item['field']?.toString() ?? '';
          final message = item['message']?.toString() ?? '';

          if (field.isNotEmpty && message.isNotEmpty) {
            return '$field: $message';
          }

          return message;
        }

        return item.toString();
      }).join('\n');
    }

    return responseBody['message']?.toString() ??
        responseBody['error']?.toString() ??
        'Gagal melakukan pembayaran';
  }

  static Map<String, dynamic> _cleanBody(Map<String, dynamic> body) {
    final cleanBody = Map<String, dynamic>.from(body);

    cleanBody.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    return cleanBody;
  }

  static Map<String, dynamic> _safeDecode(String source) {
    try {
      final decoded = json.decode(source);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  static PaymentModel _parsePaymentResponse(
    Map<String, dynamic> body,
    PaymentModel fallback,
  ) {
    final data = body['data'];

    if (data is Map<String, dynamic> && data['payment'] != null) {
      return PaymentModel.fromJson(data['payment']);
    }

    if (data is Map<String, dynamic>) {
      return PaymentModel.fromJson(data);
    }

    return fallback;
  }

  static Future<List<PaymentModel>> getPayments() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.paymentsPrefix}',
    );

    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);
    final body = _safeDecode(response.body);

    if (response.statusCode == 200) {
      final data = body['data'];

      List paymentsJson = [];

      if (data is Map<String, dynamic> && data['payments'] != null) {
        paymentsJson = data['payments'];
      } else if (data is List) {
        paymentsJson = data;
      }

      return paymentsJson.map((item) {
        return PaymentModel.fromJson(item);
      }).toList();
    } else {
      throw Exception(body['message'] ?? 'Gagal mengambil data pembayaran');
    }
  }
}
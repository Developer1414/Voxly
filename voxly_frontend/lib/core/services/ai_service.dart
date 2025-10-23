import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiHintModel {
  String hint;
  bool isSuccessfully;

  AiHintModel({required this.hint, required this.isSuccessfully});

  factory AiHintModel.init() => AiHintModel(hint: '', isSuccessfully: false);
}

class AiService {
  AiService._();

  static AiService instance = AiService._();

  final baseUrl = 'https://voxly-audio.ru';

  Future<AiHintModel> request(String prompt) async {
    final url = Uri.parse('$baseUrl/generate-hint');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return AiHintModel(
          hint: data['hint'].toString().trim(),
          isSuccessfully: true,
        );
      } else {
        final errorData = jsonDecode(response.body);
        print("Error ${response.statusCode}: ${errorData['error']}");

        return AiHintModel(
          hint: 'Ошибка генерации. Повторите позже.',
          isSuccessfully: false,
        );
      }
    } on Exception catch (e) {
      print('Network/Connection Error: $e');

      return AiHintModel(
        hint: 'Нет соединения с сервером. Повторите позже.',
        isSuccessfully: false,
      );
    }
  }
}

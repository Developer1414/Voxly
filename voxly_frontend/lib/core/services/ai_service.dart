import 'dart:convert';

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

  final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

  final String model = 'meituan/longcat-flash-chat:free';

  Future<AiHintModel> request(String prompt) async {
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return AiHintModel(
          hint: data['choices'][0]['message']['content'].toString().trim(),
          isSuccessfully: true,
        );
      } else {
        print("Error ${response.statusCode}: ${response.body}");

        return AiHintModel(
          hint: 'Не удалось сгенерировать подсказку. Повторите позже.',
          isSuccessfully: false,
        );
      }
    } on Exception catch (e) {
      print('Error: $e');

      return AiHintModel(
        hint: 'Не удалось сгенерировать подсказку. Повторите позже.',
        isSuccessfully: false,
      );
    }
  }
}

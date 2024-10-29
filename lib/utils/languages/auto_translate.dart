import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String apiKey = '';

Future<String> translateText(String text, String targetLang) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final prompt = 'Please translate the following text to $targetLang: $text';

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': 1000,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'].toString().trim();
  } else {
    throw Exception(
        'Translation failed: ${response.statusCode}, ${response.body}');
  }
}

Future<void> translateAndAppendJson() async {
  final inputFilename = 'en_us.json';

  if (await File(inputFilename).exists()) {
    final jsonString = await File(inputFilename).readAsString();
    final data = jsonDecode(jsonString);

    final languageMapping = {
      'da': 'dk',
      'de': 'de',
      'es': 'es',
      'fr': 'fr',
      'hi': 'hi',
      'ja': 'jp',
      'ko': 'ko',
      'ru': 'ru',
      'zh': 'cn'
    };

    for (var lang in languageMapping.keys) {
      final landescode = languageMapping[lang];
      final outputFilename = '${lang}_$landescode.json';

      Map<String, dynamic> langData = {};

      if (await File(outputFilename).exists()) {
        final langJsonString = await File(outputFilename).readAsString();
        langData = jsonDecode(langJsonString);
      }

      for (var entry in data.entries) {
        if (!langData.containsKey(entry.key)) {
          try {
            final translatedValue = await translateText(entry.value, lang);
            langData[entry.key] = translatedValue;
          } catch (e) {
            print('Error translating "${entry.value}": $e');
            exit(1);
          }
        }
      }

      await File(outputFilename).writeAsString(jsonEncode(langData));
      print(
          'Translation for $inputFilename completed and saved in $outputFilename.');
    }
  } else {
    print('$inputFilename was not found.');
    exit(1);
  }
}

void main() async {
  await translateAndAppendJson();
}

import 'dart:convert';

import 'package:core/core.dart';
import 'package:http/http.dart' as http;

import '../domain/assistant_mode.dart';

class OpenAiResponsesClient {
  OpenAiResponsesClient({
    http.Client? httpClient,
    this.model = 'gpt-4.1-mini',
    this.endpoint = 'https://api.openai.com/v1/responses',
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String model;
  final String endpoint;

  Future<String> generateCommentary({
    required String apiKey,
    required AssistantMode mode,
    required String question,
    required List<RetrievedPassage> sources,
    required bool highRisk,
  }) async {
    final Uri uri = Uri.parse(endpoint);
    final http.Response response = await _httpClient.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        'model': model,
        'input': <Object?>[
          <String, Object?>{
            'role': 'developer',
            'content': <Object?>[
              <String, String>{
                'type': 'input_text',
                'text': _developerPrompt(highRisk: highRisk),
              },
            ],
          },
          <String, Object?>{
            'role': 'user',
            'content': <Object?>[
              <String, String>{
                'type': 'input_text',
                'text': _userPrompt(
                  mode: mode,
                  question: question,
                  sources: sources,
                ),
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response.body));
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> output =
        json['output'] as List<dynamic>? ?? <dynamic>[];
    final StringBuffer buffer = StringBuffer();

    for (final dynamic entry in output) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final List<dynamic> content =
          entry['content'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic contentEntry in content) {
        if (contentEntry is! Map<String, dynamic>) {
          continue;
        }
        if (contentEntry['type'] == 'output_text') {
          final String text = contentEntry['text'] as String? ?? '';
          if (text.trim().isNotEmpty) {
            if (buffer.isNotEmpty) {
              buffer.writeln();
            }
            buffer.write(text.trim());
          }
        }
      }
    }

    final String result = buffer.toString().trim();
    if (result.isEmpty) {
      throw Exception('OpenAI returned an empty response.');
    }
    return result;
  }

  void dispose() {
    _httpClient.close();
  }

  String _developerPrompt({
    required bool highRisk,
  }) {
    final StringBuffer prompt = StringBuffer()
      ..writeln(
        'You are a cautious Islamic study assistant. You are not a scholar, mufti, or fatwa service.',
      )
      ..writeln(
        'Use only the supplied source passages. Do not rely on outside knowledge.',
      )
      ..writeln(
        'If the supplied passages do not clearly answer the question, set the Answer section exactly to: I don\'t know from the current sources.',
      )
      ..writeln(
        'Return exactly two sections and nothing else.',
      )
      ..writeln('Answer:')
      ..writeln(
        '<1 to 3 short sentences that answer cautiously and do not overclaim>',
      )
      ..writeln('Commentary:')
      ..writeln(
        '<Short commentary that clearly stays within the supplied passages, avoids definitive fatwa language, and references the supplied citations in parentheses>',
      );

    if (highRisk) {
      prompt.writeln(
        'This question is high risk. Keep the answer especially cautious and explicitly recommend qualified scholars and relevant professionals in the Commentary section.',
      );
    }

    return prompt.toString();
  }

  String _userPrompt({
    required AssistantMode mode,
    required String question,
    required List<RetrievedPassage> sources,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Mode: ${mode.label}')
      ..writeln('Question: $question')
      ..writeln()
      ..writeln('Use only these retrieved sources:');

    for (int index = 0; index < sources.length; index += 1) {
      final RetrievedPassage source = sources[index];
      buffer
        ..writeln('[${index + 1}] ${source.reference} - ${source.title}')
        ..writeln('Attribution: ${source.attribution}')
        ..writeln('Quote:')
        ..writeln(source.quote)
        ..writeln();
    }

    return buffer.toString();
  }

  String _extractError(String rawBody) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(rawBody) as Map<String, dynamic>;
      final Map<String, dynamic>? error =
          json['error'] as Map<String, dynamic>?;
      final String? message = error?['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Fall back to the raw body below.
    }
    return rawBody;
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../data/models/chat_message.dart';
import '../config/app_config.dart';
import '../error/app_exception.dart';

class OpenAiApiClient {
  OpenAiApiClient({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(minutes: 2)));

  final Dio _dio;

  bool _isGroqModel(String model) {
    return model.startsWith('llama') ||
        model.startsWith('mixtral') ||
        model.startsWith('gemma') ||
        model.startsWith('meta-llama') ||
        model.startsWith('qwen') ||
        model.startsWith('groq') ||
        model.startsWith('whisper-large-v3');
  }

  bool _isGeminiModel(String model) {
    return model.startsWith('gemini');
  }

  Map<String, String> _headersFor(String model) {
    if (_isGeminiModel(model)) {
      final key = AppConfig.geminiApiKey;
      if (key.isEmpty) {
        throw const AppException('Gemini API key is missing. Add GEMINI_API_KEY to env.local.json');
      }
      return {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'};
    }

    final key = _isGroqModel(model) ? AppConfig.groqApiKey : AppConfig.openAiApiKey;
    if (key.isEmpty) {
      final provider = _isGroqModel(model) ? 'Groq' : 'OpenAI';
      throw AppException('$provider API key is missing. Add ${_isGroqModel(model) ? 'GROQ_API_KEY' : 'OPENAI_API_KEY'} in env.local.json.');
    }
    return {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'};
  }

  String _baseUrlFor(String model) {
    if (_isGeminiModel(model)) {
      return 'https://generativelanguage.googleapis.com/v1beta/openai';
    }
    return _isGroqModel(model) ? 'https://api.groq.com/openai/v1' : 'https://api.openai.com/v1';
  }

  Stream<String> streamResponse({required List<ChatMessage> messages, required String model}) async* {
    if (_isGroqModel(model) && !AppConfig.hasGroqKey) {
      throw const AppException('Groq API key is missing. Add GROQ_API_KEY in env.local.json.');
    }
    if (!_isGroqModel(model) && !_isGeminiModel(model) && !AppConfig.hasOpenAiKey) {
      throw const AppException('OpenAI API key is missing. Add OPENAI_API_KEY in env.local.json.');
    }

    final hasImage = messages.any((m) => m.metadata.containsKey('image_base64'));
    final supportsVision = model.contains('scout') || model.contains('gpt-4o') || model.contains('gemini') || model.contains('vision');
    final shouldStream = !hasImage && !model.contains('scout');

    try {
      final response = await _dio.post<ResponseBody>(
        '${_baseUrlFor(model)}/chat/completions',
        data: {
          'model': model,
          'messages': messages.map((message) {
            final imageBase64 = message.metadata['image_base64'] as String?;
            if (imageBase64 != null && supportsVision) {
              final contentArray = <Map<String, dynamic>>[];
              if (message.content.isNotEmpty) {
                contentArray.add({'type': 'text', 'text': message.content});
              }
              contentArray.add({
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
              });
              return {'role': message.role.name, 'content': contentArray};
            }
            return {'role': message.role.name, 'content': message.content};
          }).toList(),
          if (shouldStream) 'stream': true,
        },
        options: Options(
          headers: {..._headersFor(model), if (shouldStream) 'Accept': 'text/event-stream', if (!shouldStream) 'Accept': 'application/json'},
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      if (!shouldStream) {
        final bytes = await stream.expand((b) => b).toList();
        final jsonString = utf8.decode(bytes);
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          if (message != null && message['content'] != null) {
            yield message['content'] as String;
          }
        }
        return;
      }

      await for (final line in stream.map<List<int>>((chunk) => chunk).transform(utf8.decoder).transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') return;

        try {
          final event = jsonDecode(data) as Map<String, dynamic>;
          final choices = event['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;

          final delta = choices[0]['delta'] as Map<String, dynamic>?;
          if (delta == null) continue;

          final content = delta['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        } catch (_) {}
      }
    } on DioException catch (error) {
      throw AppException(_dioErrorMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<String> generateImage({required String prompt, required String model}) async {
    if (!_isGroqModel(model) && !AppConfig.hasOpenAiKey) {
      throw const AppException('OpenAI API key is missing. Add OPENAI_API_KEY in env.local.json.');
    }
    // Note: Groq does not currently support image generation, so this will route to OpenAI or fail if model is Groq.

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${_baseUrlFor(model)}/images/generations',
        data: {'model': model, 'prompt': prompt, 'size': '1024x1024'},
        options: Options(headers: _headersFor(model)),
      );

      final data = response.data?['data'] as List<dynamic>? ?? const [];
      final first = data.isEmpty ? null : data.first as Map<String, dynamic>;
      return (first?['url'] ?? first?['b64_json'] ?? '').toString();
    } on DioException catch (error) {
      throw AppException(_dioErrorMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<String> textToSpeech({required String text, required String model, String voice = 'alloy'}) async {
    if (!_isGroqModel(model) && !AppConfig.hasOpenAiKey) {
      throw const AppException('OpenAI API key is missing. Add OPENAI_API_KEY in env.local.json.');
    }
    // Note: Groq does not currently support TTS, so this will route to OpenAI or fail if model is Groq.

    try {
      final response = await _dio.post<List<int>>(
        '${_baseUrlFor(model)}/audio/speech',
        data: {'model': model, 'voice': voice, 'input': text, 'format': 'mp3'},
        options: Options(headers: _headersFor(model), responseType: ResponseType.bytes),
      );

      return base64Encode(response.data ?? const []);
    } on DioException catch (error) {
      throw AppException(_dioErrorMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<String> transcribeAudio({required String filePath, required String model}) async {
    if (!_isGroqModel(model) && !AppConfig.hasOpenAiKey) {
      throw const AppException('OpenAI API key is missing. Add OPENAI_API_KEY in env.local.json.');
    }

    try {
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(filePath), 'model': model});

      final response = await _dio.post<Map<String, dynamic>>(
        '${_baseUrlFor(model)}/audio/transcriptions',
        data: formData,
        options: Options(headers: _headersFor(model)..remove('Content-Type')),
      );

      return response.data?['text']?.toString() ?? '';
    } on DioException catch (error) {
      throw AppException(_dioErrorMessage(error), statusCode: error.response?.statusCode);
    }
  }

  String _dioErrorMessage(DioException error) {
    if (error.response?.statusCode == 429) {
      return 'OpenAI quota exceeded or rate limit reached. Please check your OpenAI billing dashboard and ensure you have active credits.';
    }
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['error']?['message']?.toString() ?? data.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return error.message ?? 'OpenAI request failed';
  }
}

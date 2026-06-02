import '../../core/network/openai_api_client.dart';
import '../../domain/repositories/openai_repository.dart';
import '../models/chat_message.dart';

class OpenAiRepositoryImpl implements OpenAiRepository {
  OpenAiRepositoryImpl(this._client);

  final OpenAiApiClient _client;

  @override
  Stream<String> streamTextReply({
    required List<ChatMessage> messages,
    required String model,
  }) {
    return _client.streamResponse(messages: messages, model: model);
  }

  @override
  Future<String> generateImage({
    required String prompt,
    required String model,
  }) {
    return _client.generateImage(prompt: prompt, model: model);
  }

  @override
  Future<String> textToSpeech({
    required String text,
    required String model,
    String voice = 'alloy',
  }) {
    return _client.textToSpeech(text: text, model: model, voice: voice);
  }

  @override
  Future<String> transcribeAudio({
    required String filePath,
    required String model,
  }) {
    return _client.transcribeAudio(filePath: filePath, model: model);
  }
}

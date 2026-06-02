import 'package:chatgpt_clone_pritesh/data/models/chat_message.dart';

abstract class OpenAiRepository {
  Stream<String> streamTextReply({
    required List<ChatMessage> messages,
    required String model,
  });

  Future<String> generateImage({required String prompt, required String model});

  Future<String> textToSpeech({
    required String text,
    required String model,
    String voice = 'alloy',
  });

  Future<String> transcribeAudio({
    required String filePath,
    required String model,
  });
}

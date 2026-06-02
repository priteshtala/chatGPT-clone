class AppConfig {
  const AppConfig._();

  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const defaultTextModel = String.fromEnvironment(
    'OPENAI_TEXT_MODEL',
    defaultValue: 'meta-llama/llama-4-scout-17b-16e-instruct',
  );
  static const defaultImageModel = String.fromEnvironment(
    'OPENAI_IMAGE_MODEL',
    defaultValue: 'dall-e-3',
  );
  static const defaultSpeechModel = String.fromEnvironment(
    'OPENAI_SPEECH_MODEL',
    defaultValue: 'tts-1',
  );

  static const groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasOpenAiKey => openAiApiKey.isNotEmpty;
  static bool get hasGroqKey => groqApiKey.isNotEmpty;
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

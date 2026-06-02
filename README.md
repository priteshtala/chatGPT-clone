# ChatGPT Clone (Flutter)

A modern, multimodal ChatGPT clone built with Flutter, utilizing Clean Architecture and Cubit state management. This app integrates with various AI models like Groq, Gemini, and OpenAI, and supports text, image (Vision), and voice notes (Whisper API) capabilities.

## 🚀 Getting Started

### 1. Environment Setup
Before running the app, you need to set up your environment variables (API keys).

1. Rename the `env.example.json` file to `env.local.json` (or create a new `env.local.json` in the root folder).
2. Add your API keys inside `env.local.json`:
   ```json
   {
     "OPENAI_API_KEY": "your_openai_key",
     "GROQ_API_KEY": "your_groq_key",
     "GEMINI_API_KEY": "your_gemini_key",
     "SUPABASE_URL": "your_supabase_url",
     "SUPABASE_ANON_KEY": "your_supabase_anon_key"
   }
   ```

### 2. How to Run the App
Because this project uses environment variables injected at compile time, you **MUST** run the app using the `--dart-define-from-file` flag.

Run this command in your terminal:
```bash
flutter run --dart-define-from-file=env.local.json
```

If you are using Android Studio or VS Code, make sure to add `--dart-define-from-file=env.local.json` to your run configuration arguments.

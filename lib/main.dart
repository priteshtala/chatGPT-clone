import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/config/app_config.dart';
import 'core/network/openai_api_client.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/chat_cache_data_source.dart';
import 'data/datasources/supabase_chat_data_source.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/openai_repository_impl.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/view/login_page.dart';
import 'features/chat/cubit/chat_cubit.dart';
import 'features/chat/view/chat_page.dart';
import 'features/settings/cubit/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabaseConfig) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }

  final preferences = await SharedPreferences.getInstance();
  final cacheDataSource = ChatCacheDataSource(preferences);
  final supabaseDataSource = AppConfig.hasSupabaseConfig ? SupabaseChatDataSource(Supabase.instance.client) : null;

  runApp(
    ChatGptCloneApp(
      chatRepository: ChatRepositoryImpl(cacheDataSource: cacheDataSource, supabaseDataSource: supabaseDataSource),
      openAiRepository: OpenAiRepositoryImpl(OpenAiApiClient()),
      authRepository: AuthRepository(Supabase.instance.client),
      preferences: preferences,
    ),
  );
}

class ChatGptCloneApp extends StatelessWidget {
  const ChatGptCloneApp({
    required this.chatRepository,
    required this.openAiRepository,
    required this.authRepository,
    required this.preferences,
    super.key,
  });

  final ChatRepositoryImpl chatRepository;
  final OpenAiRepositoryImpl openAiRepository;
  final AuthRepository authRepository;
  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: chatRepository),
        RepositoryProvider.value(value: openAiRepository),
        RepositoryProvider.value(value: authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(preferences)..load()),
          BlocProvider(create: (_) => AuthCubit(authRepository: authRepository)),
        ],
        child: BlocSelector<SettingsCubit, SettingsState, ThemeMode>(
          selector: (state) => state.themeMode,
          builder: (context, themeMode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'ChatGPT Clone',
              themeMode: themeMode,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  if (authState.status == AuthStatus.authenticated) {
                    return BlocProvider(
                      create: (_) => ChatCubit(chatRepository: chatRepository, openAiRepository: openAiRepository)..loadConversations(),
                      child: const ChatPage(),
                    );
                  }
                  return const LoginPage();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

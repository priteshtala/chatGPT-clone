import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    _authStateSubscription = _authRepository.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        emit(state.copyWith(status: AuthStatus.authenticated, clearError: true));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated, clearError: true));
      }
    });
  }

  final AuthRepository _authRepository;
  StreamSubscription<dynamic>? _authStateSubscription;

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  Future<void> signIn({required String email, required String password}) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Email and password cannot be empty.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      await _authRepository.signIn(email: email.trim(), password: password);
    } on supabase.AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'An unexpected error occurred.',
      ));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Email and password cannot be empty.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      await _authRepository.signUp(email: email.trim(), password: password);
      // If Supabase auto-logged them in because email confirmation is off, log them out immediately
      // so they are forced to log in manually as requested.
      await _authRepository.signOut();
      
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Registration successful! Please Sign In.',
        isSuccess: true,
      ));
    } on supabase.AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'An unexpected error occurred.',
      ));
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (_) {}
  }
}

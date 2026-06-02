import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.initial, this.errorMessage, this.isSuccess = false});

  final AuthStatus status;
  final String? errorMessage;
  final bool isSuccess;

  AuthState copyWith({AuthStatus? status, String? errorMessage, bool? isSuccess, bool clearError = false}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? (clearError ? false : this.isSuccess),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, isSuccess];
}

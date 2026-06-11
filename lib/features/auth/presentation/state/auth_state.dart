class AuthState {
  final bool isSuccess;
  final String? error;

  AuthState({
    this.isSuccess = false,
    this.error,
  });

  AuthState copyWith({
    bool? isSuccess,
    String? error,
  }) {
    return AuthState(
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
    );
  }
}

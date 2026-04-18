abstract interface class AuthSessionCoordinator {
  Future<String> getValidAccessToken();

  Future<String> refreshAccessToken();

  Future<void> handleUnauthorized();
}

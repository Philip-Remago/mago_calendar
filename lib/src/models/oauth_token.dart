class OAuthToken {
  OAuthToken({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));

  factory OAuthToken.fromJson(Map<String, dynamic> json) {
    final expiresAtValue = json['expires_at']?.toString();
    if (expiresAtValue != null) {
      return OAuthToken(
        accessToken: json['access_token']?.toString() ?? '',
        refreshToken: json['refresh_token']?.toString(),
        expiresAt: DateTime.parse(expiresAtValue),
      );
    }
    final expiresIn = int.tryParse(json['expires_in']?.toString() ?? '');
    return OAuthToken(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString(),
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn ?? 3600)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

/// Stub for non-web platforms — should never be called.
Future<String> signInWithGooglePopup(String authUrl) {
  throw UnsupportedError('signInWithGooglePopup is only supported on web');
}

Future<String> signInWithMicrosoftPopup(String authUrl) {
  throw UnsupportedError('signInWithMicrosoftPopup is only supported on web');
}

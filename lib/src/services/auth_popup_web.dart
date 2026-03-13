import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> authPopup(String authUrl, {String windowName = 'auth'}) async {
  final screenW = web.window.screen.width;
  final screenH = web.window.screen.height;
  const popupW = 500;
  const popupH = 600;
  final left = ((screenW - popupW) / 2).round();
  final top = ((screenH - popupH) / 2).round();

  final features =
      'width=$popupW,height=$popupH,left=$left,top=$top,toolbar=no,menubar=no,scrollbars=yes,resizable=yes';

  final popup = web.window.open(authUrl, windowName, features);

  final completer = Completer<String>();
  web.EventListener? listener;

  listener = (web.Event event) {
    final msgEvent = event as web.MessageEvent;

    if (msgEvent.origin != web.window.location.origin) return;

    final data = msgEvent.data.dartify();
    if (data is! Map) return;

    final callbackUrl = data['flutter-web-auth-2'];
    if (callbackUrl is! String) return;

    web.window.removeEventListener('message', listener);
    if (!completer.isCompleted) {
      completer.complete(callbackUrl);
    }
  }.toJS;

  web.window.addEventListener('message', listener);

  Timer.periodic(const Duration(milliseconds: 500), (timer) {
    if (popup == null || popup.closed) {
      timer.cancel();
      web.window.removeEventListener('message', listener);
      if (!completer.isCompleted) {
        completer.completeError(StateError('Sign-in popup was closed'));
      }
    }
  });

  return completer.future;
}

Future<String> signInWithGooglePopup(String authUrl) async {
  final callbackUrl = await authPopup(authUrl, windowName: 'google_auth');
  final uri = Uri.parse(callbackUrl);
  final params = Uri.splitQueryString(uri.fragment);
  final token = params['access_token'];

  if (token != null && token.isNotEmpty) {
    return token;
  }
  throw StateError('Google auth failed: no access token in response');
}

Future<String> signInWithMicrosoftPopup(String authUrl) async {
  return authPopup(authUrl, windowName: 'microsoft_auth');
}

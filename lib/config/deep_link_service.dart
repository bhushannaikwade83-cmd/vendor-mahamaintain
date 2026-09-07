import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

/// Handles the `mahavendor://` custom scheme DigiLocker redirects back into
/// after the vendor authorizes on DigiLocker's own site - see
/// server/digilocker_callback.php, which sends the browser here once the
/// OAuth callback finishes.
class DeepLinkService {
  static AppLinks? _appLinks;
  static StreamSubscription<Uri>? _subscription;

  static void init(GoRouter router) {
    _appLinks = AppLinks();
    _subscription = _appLinks!.uriLinkStream.listen((uri) {
      if (uri.scheme == 'mahavendor' && uri.host == 'digilocker-callback') {
        router.go('/verification');
      }
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

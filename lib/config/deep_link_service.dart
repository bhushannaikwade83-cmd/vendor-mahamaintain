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
      // Handle deep link: mahavendor://digilocker-callback
      if (uri.scheme == 'mahavendor') {
        if (uri.host == 'digilocker-callback' || uri.path.contains('digilocker-callback')) {
          Future.microtask(() => router.go('/digilocker-callback'));
        }
      }
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

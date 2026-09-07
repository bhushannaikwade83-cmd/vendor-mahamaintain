import 'dart:async';
import 'dart:io';

/// Turns any caught error into something a vendor - not a developer - can
/// read and act on.
///
/// Two kinds of errors reach the UI in this app:
/// 1. Deliberately-written messages (ours, e.g. "Enter a valid amount", or
///    the backend's, e.g. "Job already taken by another partner" /
///    "Incorrect completion OTP") - these already ARE what a vendor should
///    see, so they pass through unchanged.
/// 2. Everything else - a dropped connection, a JSON parse failure because
///    the server returned an HTML error page, a raw SQL/PHP exception that
///    slipped through, a null-check crash. None of that is something a
///    vendor did wrong or can fix, so it's replaced with a plain apology
///    instead of ever showing a stack trace or "SQLSTATE[..]" on screen.
///
/// This is the one place that decides "is this the vendor's problem
/// (bad input, no signal) or ours (a bug, a server error)" - every screen
/// that shows a caught error should route it through here rather than
/// interpolating the raw exception into a string.
String friendlyErrorMessage(Object error) {
  if (error is SocketException) {
    return 'No internet connection. Check your network and try again.';
  }
  if (error is TimeoutException) {
    return 'That took too long to respond. Please try again.';
  }
  if (error is FormatException || error is TypeError || error is NoSuchMethodError) {
    return 'Something went wrong on our end. Please try again in a moment.';
  }

  final raw = error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
  if (raw.isEmpty || _looksTechnical(raw)) {
    return 'Something went wrong on our end. Please try again in a moment.';
  }
  return raw;
}

bool _looksTechnical(String message) {
  final lower = message.toLowerCase();
  const technicalMarkers = [
    'sqlstate',
    'pdoexception',
    'syntax error',
    'stack trace',
    'null check operator',
    'is not a subtype of',
    'httpexception',
    'socketexception',
    'formatexception',
    'unhandled exception',
    '.dart:',
    '.php',
    'fatal error',
    'undefined column',
    'unknown column',
    '#0 ',
    'at object.',
    'internal server error',
  ];
  return technicalMarkers.any(lower.contains) || message.length > 160;
}

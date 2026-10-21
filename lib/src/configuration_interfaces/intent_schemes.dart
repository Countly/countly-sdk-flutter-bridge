import '../countly_flutter.dart';

/// URI schemes the Android SDK blocks by default, as they can read local data, run script or
/// redirect to another app component. The Flutter SDK never allows them.
const List<String> blockedIntentSchemes = ['data', 'zip', 'intent', 'file', 'content', 'javascript', 'jar'];

/// A URI scheme as RFC 3986 defines it, in lower case.
final RegExp _uriScheme = RegExp(r'^[a-z][a-z0-9+.-]*$');

/// Returns the allowed URI schemes of [schemes] in lower case, for the config option [caller].
/// Malformed entries and the [blockedIntentSchemes] are left out with a warning. When no scheme is
/// left, it returns [current], the schemes set before, so a list can only tighten what is allowed;
/// null keeps the default of every scheme except the blocked ones.
List<String>? allowedIntentSchemesFrom(List<String> schemes, String caller, List<String>? current) {
  final List<String> allowed = [];
  for (final String entry in schemes) {
    final String scheme = entry.trim().toLowerCase();
    if (!_uriScheme.hasMatch(scheme)) {
      Countly.log('$caller, ignoring [$entry], which is not a URI scheme such as "https"', logLevel: LogLevel.WARNING);
    } else if (blockedIntentSchemes.contains(scheme)) {
      Countly.log('$caller, ignoring [$entry], as the "$scheme" scheme is always blocked', logLevel: LogLevel.WARNING);
    } else if (!allowed.contains(scheme)) {
      allowed.add(scheme);
    }
  }
  if (allowed.isNotEmpty) {
    return allowed;
  }
  if (current != null) {
    Countly.log('$caller, no allowed scheme is left, so the schemes set before stay: $current', logLevel: LogLevel.ERROR);
  } else {
    Countly.log('$caller, no allowed scheme is left, so every scheme except the blocked ones stays allowed', logLevel: LogLevel.ERROR);
  }
  return current;
}

import 'dart:io';

class PlatformUtils {
  static bool get isWeb => identical(0, 0.0) == false;

  static bool get isIOS => !isWeb && Platform.isIOS;

  static bool get isAndroid => !isWeb && Platform.isAndroid;

  static bool get isDesktop =>
      !isWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static bool get isCupertino => isIOS;

  static bool get isMaterial => !isCupertino;
}

class SubdomainUtils {
  /// Extract subdomain from hostname (habitant.dk, aab25.habitant.dk, etc.)
  /// Returns the subdomain or null if it's the main domain
  static String? extractSubdomain(String hostname) {
    final parts = hostname.split('.');

    if (parts.length <= 2) {
      return null;
    }

    return parts.first;
  }

  /// Check if hostname is a main domain (habitant.dk, localhost, etc.)
  static bool isMainDomain(String hostname) {
    return extractSubdomain(hostname) == null;
  }

  /// Get the main domain from any hostname
  static String getMainDomain(String hostname) {
    final parts = hostname.split('.');
    return parts.sublist(parts.length - 2).join('.');
  }
}

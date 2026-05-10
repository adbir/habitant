import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isWeb => kIsWeb;

  static bool get isIOS => !isWeb && Platform.isIOS;

  static bool get isAndroid => !isWeb && Platform.isAndroid;

  static bool get isDesktop =>
      !isWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static bool get isCupertino => isIOS;

  static bool get isMaterial => !isCupertino;
}

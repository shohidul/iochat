import 'dart:io';

import 'package:iochat/utilities/constants.dart';
import 'package:iochat/utilities/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserAgent {
  String _userAgent = '';

  /// private constructor
  UserAgent._();

  /// the one and only instance of this singleton
  static final _instance = UserAgent._();

  static UserAgent getInstance() {
    return _instance;
  }

  Future<void> create() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String os = Platform.operatingSystem;
    String osVer = Platform.operatingSystemVersion;
    String appVer = '${packageInfo.version}+${packageInfo.buildNumber}';
    _userAgent = '$os/$osVer iochat/$appVer (${Constants.callbackUrlScheme})';
  }

  String _getSafeAreaPadding() {
    String padding = '';

    BuildContext? context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      EdgeInsets insets = MediaQuery.of(context).padding;
      int paddingTop = insets.top.toInt();
      int paddingRight = insets.right.toInt();
      int paddingBottom = insets.bottom.toInt();
      int paddingLeft = insets.left.toInt();
      padding = '(SafeArea $paddingTop $paddingRight $paddingBottom $paddingLeft)';
    }
    return padding;
  }

  String get() {
    return '$_userAgent ${_getSafeAreaPadding()}';
  }
}

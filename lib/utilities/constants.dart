import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';

class Constants {
  Constants._();

  static String baseUrl = 'https://iochat.netlify.app'; //"https://${FlutterConfig.get('BASE_URL')}/?l=${Platform.localeName}";
  // static String baseUrl = 'https://flutter.coursepath-staging.com/?l=${Platform.localeName}';
  // static String baseUrl = 'https://leidner.eu.ngrok.io/?l=${Platform.localeName}';
  static String appTitle = 'IO Chat'; //FlutterConfig.get('APP_NAME');
  static String appShortName = 'iochat'; //FlutterConfig.get('SHORT_NAME');
  static String callbackUrlScheme = 'iochat'; //FlutterConfig.get('URL_SCHEME');
  static String sharePath = '/share'; //FlutterConfig.get('SHARE_PATH');
  static bool behindAppBar = FlutterConfig.get('BEHIND_APP_BAR') == 'true' ? true : false;

  static const double iconSize = 20;
  static const String iconWeight = 'regular';
  static const Color iconColor = Color(0xFF333333);
  static const Color badgeColor = Color(0xFFFF1919);

  static const Color progressIndicatorColor = Color(0xFF000000);
  static const Color onPressColor = Color(0xFFDCDCDC);

  static const double appBarHeight = 44;
  static const Color appBarBorderColor = Color(0xFFE0E0E0);
  static const Color appBarBackgroundColor = Colors.white;
  static const Color appBarTitleColor = Color(0xFF333333);
  static const double appBarTitleFontSize = 17;
  static const double appBarTitleLetterSpacing = -0.5;
  static const FontWeight appBarTitleFontWeight = FontWeight.bold;

  static const Color navBarBorderColor = Color(0xFFE0E0E0);
  static const Color navBarBackgroudColor = Colors.white;

  static const Color bottomSheetPlaceholderColor = Color(0xFFEBEBEB);
  static const Color bottomSheetHandleColor = Color(0xFFDBDBDB);
  static const Color bottomSheetDividerColor = Color(0xFFDCDCDC);
  static const double bottomSheetButtonHeight = 52;
  static const double bottomSheetInset = 24;
  static const double bottomSheetIconWidth = 24;
  static const double bottomSheetIconHeight = 17;
  static const String bottomSheetIconWeight = 'regular';
  static const double bottomSheetTextMarginLeft = 8;
  static const Color bottomSheetIconColor = Colors.black;
  static const double bottomSheetFontSize = 17;
  static const double bottomSheetLetterSpacing = -0.4;
  static const FontWeight bottomSheetFontWeight = FontWeight.w400;

  static const String typeDevicePhone = 'PHONE';
  static const String typeDeviceTablet = 'TABLET';
  static const String https = 'https';
  static const String clientID = 'client_id';
  static const String redirectURI = 'redirect_uri';
  static const String top = 'top';
  static const String bottom = 'bottom';
  static const String logo = 'LOGO';
  static const String title = 'TITLE';
  static const String iconButton = 'ICON_BUTTON';
  static const String textButton = 'TEXT_BUTTON';
  static const String bottomSheet = 'BOTTOM_SHEET';
  static const String bottomSheetItem = 'BOTTOM_SHEET_ITEM';
  static const String bottomSheetDivider = 'BOTTOM_SHEET_DIVIDER';
  static const String openUrl = 'OPEN_URL';
  static const String clickElement = 'CLICK_ELEMENT';
  static const String goBack = 'GO_BACK';
  static const String showView = 'SHOW_VIEW';
  static const String reset = 'RESET';

  static const List<String> unsupportedFileExtensions = <String>['txt', 'xml'];
  static String customDomains = ''; //FlutterConfig.get('CUSTOM_DOMAINS');
  static const List<String> allowedDomains = <String>[
    'netlify.app',
    'ngrok.io', // dev purpose
    'ngrok-free.app'
  ];
  static const List<String> disallowedDomains = <String>[
    'www.coursepath.com', //
    'support.coursepath.com', //
    'changelog.coursepath.com', //
    'www.viadesk.com', //
    'support.viadesk.com', //
    'changelog.viadesk.com' //
  ];

  static const List<String> loginUrls = <String>[
    'login.viadesk.com', //
    'login.coursepath.com' //
  ];

  // messages
  static const String labelBusyLoading = 'Busy loading. Please try again later.';
  static String labelDownloadCompleteIOS = 'Downloaded to Files > On My iPhone > $appTitle';

  // error codes
  static const int offline = -1009;
}

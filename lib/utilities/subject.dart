import 'package:iochat/utilities/temp_file.dart';
import 'package:flutter_keychain/flutter_keychain.dart';

class Subject {
  static const domainUrlKey = 'domainUrl';
  static const authenticationCookieKey = 'authenticationCookie';

  String _currentUrl = '';
  String _domainUrl = '';
  String _authenticationCookie = '';

  TempFile tempFile = TempFile.getInstance();

  /// private constructor
  Subject._();

  /// the one and only instance of this singleton
  static final _instance = Subject._();

  static Subject getInstance() {
    return _instance;
  }

  Future<void> clear() async {
    FlutterKeychain.clear();
  }

  Future<void> load() async {
    // hack to check the app is reinstalled
    bool isExist = await tempFile.isTempFileExists();
    if (!isExist) {
      FlutterKeychain.clear();
    }

    String url = await FlutterKeychain.get(key: domainUrlKey) ?? '';
    String cookie = await FlutterKeychain.get(key: authenticationCookieKey) ?? '';
    update(url, cookie);
  }

  bool update(final String newUrl, String newCookie) {
    int changes = 0;

    if (newUrl != _currentUrl) {
      _currentUrl = newUrl;
      ++changes;
    }

    final String newDomainUrl = 'https://${Uri.parse(newUrl).host}';
    if (newDomainUrl != _domainUrl) {
      _domainUrl = newDomainUrl;
      ++changes;
    }

    if (newCookie.isNotEmpty && newCookie != _authenticationCookie) {
      _authenticationCookie = newCookie;
      ++changes;
    }

    return changes > 0;
  }

  Future<void> save(String url, String cookie) async {
    await FlutterKeychain.put(key: domainUrlKey, value: url);
    await FlutterKeychain.put(key: authenticationCookieKey, value: cookie);

    tempFile.create();
  }

  String getCurrentUrl() {
    return _currentUrl;
  }

  String getDomainUrl() {
    return _domainUrl;
  }

  String getAuthenticationCookie() {
    return _authenticationCookie;
  }

  bool hasCurrentUrl() {
    return _currentUrl.isNotEmpty && _domainUrl.startsWith('http');
  }

  bool hasDomainUrl() {
    return _domainUrl.isNotEmpty && _domainUrl.startsWith('http');
  }

  bool hasAuthenticationCookie() {
    return _authenticationCookie.isNotEmpty;
  }

  // if domainUrl or session changed, send the Firebase device token to the server
  bool isChanged(final String newUrl, String newCookie) {
    final newDomainUrl = 'https://${Uri.parse(newUrl).host}';
    return newDomainUrl != _domainUrl || newCookie != _authenticationCookie;
  }
}

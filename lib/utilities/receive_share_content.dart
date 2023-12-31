import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:iochat/utilities/useragent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'constants.dart';
import 'common_util.dart';
import 'di.dart';
import 'subject.dart';

class ReceiveShareContent {
  final Completer<InAppWebViewController> _webViewCompleter = locator<Completer<InAppWebViewController>>();

  ReceiveShareContent._();

  /// the one and only instance of this singleton
  static final _instance = ReceiveShareContent._();

  static ReceiveShareContent getInstance() {
    return _instance;
  }

  bool _isSharePanel = false;
  String _sharedText = '';
  final List<File> _sharedAttachments = <File>[];

  bool _hasSharedContent() {
    return _sharedText.isNotEmpty || _sharedAttachments.isNotEmpty;
  }

  bool isSharePanel() {
    return _isSharePanel;
  }

  void setSharePanel(bool val) {
    _isSharePanel = val;
  }

  void listenShareMediaFiles(BuildContext context) {
    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value != null) {
        bool isExternalUrl = isSharedTextAnUrl(value) && !isInternalUrl(WebUri(value));
        if (!isSharedTextAnUrl(value) || isExternalUrl) {
          setSharePanel(true);
          _sharedText = value;
          Future.delayed(const Duration(milliseconds: 500), () {
            loadShareUrl();
          });
        }
      }
    }, onError: (err) {
      debugPrint('$err');
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    ReceiveSharingIntent.getTextStream().listen((String value) {
      bool isExternalUrl = isSharedTextAnUrl(value) && !isInternalUrl(WebUri(value));
      if (!isSharedTextAnUrl(value) || isExternalUrl) {
        setSharePanel(true);
        _sharedText = value;
        loadShareUrl();
      }
    }, onError: (err) {
      debugPrint('$err');
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        setSharePanel(true);
        _populateShareMedia(context, value);
        Future.delayed(const Duration(milliseconds: 500), () {
          loadShareUrl();
        });
      }
    }, onError: (err) {
      debugPrint('$err');
    });

    // For sharing images coming from outside the app while the app is in the memory
    ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
      setSharePanel(true);
      _populateShareMedia(context, value);
      loadShareUrl();
    }, onError: (err) {
      debugPrint('$err');
    });
  }

  void _populateShareMedia(BuildContext context, List<SharedMediaFile> value) {
    _sharedAttachments.clear();
    for (var element in value) {
      final file = File(Uri.decodeFull(
        Platform.isIOS
            ? element.type == SharedMediaType.FILE
                ? element.path.toString().replaceAll('file://', '')
                : element.path
            : element.path,
      ));
      int sizeInBytes = file.lengthSync();
      double sizeInMb = double.parse((sizeInBytes / (1000 * 1000)).toStringAsFixed(1));

      if (element.type == SharedMediaType.VIDEO) {
        String title = 'Video is not supported!';
        String content = 'Please share Image & File only.';
        showAlertDialog(context, title, content);
      } else if (sizeInMb > 10) {
        String title = 'File is too large!';
        String content = 'Maximum size of Image or File is 10MB.';
        showAlertDialog(context, title, content);
      } else {
        _sharedAttachments.add(file);
      }
    }
  }

  void loadShareUrl() {
    if (_hasSharedContent()) {
      _webViewCompleter.future.then((controller) async {
        controller.loadUrl(urlRequest: _getShareUrlRequest()).whenComplete(() {
          _clear();
        });
      });
    }
  }

  URLRequest _getShareUrlRequest() {
    Subject subject = Subject.getInstance();
    String sessionId = subject.getAuthenticationCookie();
    WebUri uri = WebUri('${subject.getDomainUrl()}${Constants.sharePath}');

    List<String> attachmentArray = [];
    if (_sharedAttachments.isNotEmpty) {
      for (File attachment in _sharedAttachments) {
        List<int> attachmentBytes = attachment.readAsBytesSync();
        String base64 = base64Encode(attachmentBytes);
        attachmentArray
            .add('{"base64UploadName" : "${attachment.path.split('/').last}", "base64UploadData":"$base64"}');
      }
    }

    Map<String, String> headers = getHeaders();
    headers.addAll({
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Session $sessionId',
      'User-Agent': UserAgent.getInstance().get()
    });

    return URLRequest(
        url: uri,
        method: 'POST',
        body: _sharedAttachments.isNotEmpty
            ? Uint8List.fromList(utf8.encode('attachmentArray=$attachmentArray'))
            : isSharedTextAnUrl(_sharedText)
                ? Uint8List.fromList(utf8.encode('url=$_sharedText'))
                : Uint8List.fromList(utf8.encode('messageBody=$_sharedText')),
        headers: headers);
  }

  Future<void> _clear() async {
    _sharedText = '';

    // delete the attachment after you finish using it
    for (var attachment in _sharedAttachments) {
      try {
        if (await attachment.exists()) {
          await attachment.delete();
        }
      } catch (e) {
        log(e.toString());
      }
    }
    _sharedAttachments.clear();
  }

  bool isSharedTextAnUrl(String text) {
    Uri? sharedUri = Uri.tryParse(text);
    if (sharedUri != null && sharedUri.hasAbsolutePath) {
      return true;
    }
    return false;
  }
}

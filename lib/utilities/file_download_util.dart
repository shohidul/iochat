import 'dart:io';

import 'package:iochat/utilities/local_notification_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

import 'constants.dart';

class FileDownloadUtil {
  static String _downloadStartRequestFilename = '';

  static void setDownloadRequestFilename(String filename) {
    _downloadStartRequestFilename = Uri.decodeFull(filename);
  }

  static String getDownloadRequestFilename() {
    return _downloadStartRequestFilename;
  }

  static Future<void> downloadFile(WebUri url) async {
    String requestFilename = getDownloadRequestFilename();
    String name = requestFilename.substring(0, requestFilename.lastIndexOf('.'));
    String ext = requestFilename.split('.').last;

    // Create a regular expression to match filenames that start with `name`,
    // optionally followed by a space, open parenthesis, one or more digits, close parenthesis, and end with `ext`.
    // e.g. file.txt, file (1).txt, file (2).txt, etc
    RegExp fileNameRegex = RegExp('^${RegExp.escape(name)}( \\([0-9]+\\))?\\.$ext\$');

    Directory appDocPath = await getApplicationDocumentsDirectory();
    String dirPathToReadFiles = Platform.isIOS ? appDocPath.path : '/storage/emulated/0/Download';

    // get a list of all files from the downloaded location those match the file name and extension
    List<FileSystemEntity> matchingFiles = Directory(dirPathToReadFiles)
        .listSync()
        .where((file) =>
            file is File && //
            fileNameRegex.hasMatch(file.path.split('/').last))
        .toList();

    // add suffix if any empty slot found
    if (matchingFiles.isNotEmpty) {
      bool isExist = matchingFiles.any((element) => element.path.split('/').last == requestFilename);
      int i = 0;
      while (isExist) {
        i++;
        isExist = matchingFiles.any((element) => element.path.split('/').last == '$name ($i).$ext');
      }
      requestFilename = i == 0 ? requestFilename : '$name ($i).$ext';
      setDownloadRequestFilename(requestFilename);
    }

    // save file
    String cookiesString = await _getCookieString(url);
    await FlutterDownloader.enqueue(
        url: url.toString(),
        savedDir: appDocPath.path,
        fileName: requestFilename,
        headers: {
          HttpHeaders.connectionHeader: 'keep-alive',
          HttpHeaders.cookieHeader: cookiesString,
        },
        saveInPublicStorage: true,
        showNotification: false,
        openFileFromNotification: true,
        requiresStorageNotLow: true);
  }

  static Future<String> _getCookieString(WebUri url) async {
    List<Cookie> cookies = await CookieManager.instance().getCookies(url: url);
    return cookies.map((cookie) => '${cookie.name}=${cookie.value};').join();
  }

  static Future<void> fileDownloadStatus(data) async {
    String taskId = data[0];
    int status = data[1];

    if (DownloadTaskStatus.complete == DownloadTaskStatus.fromInt(status)) {
      DownloadTask? downloadTask = await _getDownloadTask(taskId);
      String? title = downloadTask != null ? downloadTask.filename : getDownloadRequestFilename();

      String filePath;
      if (Platform.isIOS) {
        Directory appDocPath = await getApplicationDocumentsDirectory();
        filePath = '${appDocPath.absolute.path}/${getDownloadRequestFilename()}';
      } else {
        Directory dir = Directory('/storage/emulated/0/Download');
        filePath = '${dir.absolute.path}/${getDownloadRequestFilename()}';
      }

      String data = '{"filePath": "$filePath"}';

      await LocalNotificationService.showLocalNotification(
          title: title!, //
          body: Platform.isIOS ? Constants.labelDownloadCompleteIOS : 'Downloaded Successfully', //
          payload: data);
    } else if (DownloadTaskStatus.failed == DownloadTaskStatus.fromInt(status)) {
      DownloadTask? downloadTask = await _getDownloadTask(taskId);
      String? title = downloadTask!.url;
      await LocalNotificationService.showLocalNotification(title: title, body: 'Download Failed');
    }
  }

  static Future<DownloadTask?> _getDownloadTask(String taskId) async {
    String query = 'SELECT * FROM task WHERE task_id= "$taskId"';
    List<DownloadTask>? tasks = await FlutterDownloader.loadTasksWithRawQuery(query: query);
    return tasks!.isNotEmpty ? tasks.first : null;
  }
}

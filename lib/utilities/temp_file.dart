import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class TempFile {
  /// private constructor
  TempFile._();

  /// the one and only instance of this singleton
  static final _instance = TempFile._();

  static TempFile getInstance() {
    return _instance;
  }

  void create() {
    String json = '{"isFirstRun" : "true"}';
    writeToJsonFile(json);
  }

  Future<void> writeToJsonFile(final String json) async {
    final file = await _subjectFile;
    file.writeAsString('');

    IOSink sink = file.openWrite(mode: FileMode.append);
    sink.add(utf8.encode(json));
    await sink.flush();
    await sink.close();
  }

  Future<bool> isTempFileExists() async {
    final file = await _subjectFile;
    if (file.existsSync()) {
      return true;
    }
    return false;
  }

  Future<String> get _localPath async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  Future<File> get _subjectFile async {
    final path = await _localPath;
    return File('$path/temp_subject.json');
  }
}

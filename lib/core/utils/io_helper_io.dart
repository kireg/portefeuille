import 'dart:io';
import 'io_helper.dart';

class IOHelperIO implements IOHelper {
  @override
  Future<String> readFileAsString(String path) => File(path).readAsString();

  @override
  Future<void> writeFileAsString(String path, String content) => File(path).writeAsString(content);

  @override
  bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

IOHelper getInstance() => IOHelperIO();

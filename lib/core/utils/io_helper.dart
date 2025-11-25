import 'dart:async';

import 'io_helper_stub.dart'
    if (dart.library.io) 'io_helper_io.dart'
    if (dart.library.html) 'io_helper_web.dart';

abstract class IOHelper {
  Future<String> readFileAsString(String path);
  Future<void> writeFileAsString(String path, String content);
  bool get isDesktop;
}

IOHelper getIOHelper() => getInstance();

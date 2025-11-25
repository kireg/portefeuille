import 'io_helper.dart';

class IOHelperWeb implements IOHelper {
  @override
  Future<String> readFileAsString(String path) async {
    throw UnsupportedError('Cannot read file by path on Web');
  }

  @override
  Future<void> writeFileAsString(String path, String content) async {
    throw UnsupportedError('Cannot write file by path on Web');
  }

  @override
  bool get isDesktop => false;
}

IOHelper getInstance() => IOHelperWeb();

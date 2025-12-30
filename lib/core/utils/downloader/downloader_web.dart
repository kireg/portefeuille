import 'dart:html' as html;
import 'dart:typed_data';
import 'downloader.dart';

class WebFileDownloader implements FileDownloader {
  @override
  Future<void> downloadFile(String fileName, Uint8List bytes) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

FileDownloader getFileDownloader() => WebFileDownloader();

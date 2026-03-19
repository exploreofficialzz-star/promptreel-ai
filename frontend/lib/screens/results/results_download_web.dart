// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
  String? subject,
  String? text,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url  = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadString({
  required String content,
  required String filename,
  required String mimeType,
  String? subject,
}) async {
  final blob = html.Blob([content], mimeType);
  final url  = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

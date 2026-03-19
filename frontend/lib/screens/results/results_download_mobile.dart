import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
  String? subject,
  String? text,
}) async {
  final dir  = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType)],
    subject: subject,
    text: text,
  );
}

Future<void> downloadString({
  required String content,
  required String filename,
  required String mimeType,
  String? subject,
}) async {
  final dir  = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType)],
    subject: subject,
  );
}

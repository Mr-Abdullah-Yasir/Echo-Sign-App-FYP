import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'database_service.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  Future<String?> createBackup(int userId) async {
    final data = await DatabaseService.instance.exportUserBackup(userId);
    final jsonText = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = Uint8List.fromList(utf8.encode(jsonText));

    final now = DateTime.now();
    final stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';

    return FilePicker.platform.saveFile(
      dialogTitle: 'Save EchoSign backup',
      fileName: 'echosign_backup_$stamp.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
  }

  Future<Map<String, dynamic>?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select EchoSign backup',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    Uint8List? bytes = picked.bytes;

    if (bytes == null && picked.path != null) {
      bytes = await File(picked.path!).readAsBytes();
    }

    if (bytes == null) {
      throw const FormatException(
        'Could not read the selected backup file.',
      );
    }

    final decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'This is not a valid EchoSign backup.',
      );
    }

    return decoded;
  }

  Future<void> restoreBackup({
    required int userId,
    required Map<String, dynamic> backup,
  }) async {
    await DatabaseService.instance.restoreUserBackup(
      userId: userId,
      backup: backup,
    );
  }

  static String _two(int value) =>
      value.toString().padLeft(2, '0');
}

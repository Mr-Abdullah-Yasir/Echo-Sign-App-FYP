import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<String> copyAssetFile(String src, [String? dst]) async {
  final directory = await getApplicationSupportDirectory();
  dst ??= basename(src);

  final target = join(directory.path, dst);
  final targetFile = File(target);
  final data = await rootBundle.load(src);

  final shouldWrite =
      !await targetFile.exists() ||
      await targetFile.length() != data.lengthInBytes;

  if (shouldWrite) {
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await targetFile.writeAsBytes(bytes, flush: true);
  }

  return target;
}

Float32List pcm16BytesToFloat32(
  Uint8List bytes, [
  Endian endian = Endian.little,
]) {
  final values = Float32List(bytes.length ~/ 2);
  final data = ByteData.sublistView(bytes);

  for (var i = 0; i + 1 < bytes.length; i += 2) {
    final short = data.getInt16(i, endian);
    values[i ~/ 2] = short / 32768.0;
  }

  return values;
}

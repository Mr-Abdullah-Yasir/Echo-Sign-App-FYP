import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordService {
  static const int _iterations = 10000;

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPassword(String password, String salt) {
    var bytes = utf8.encode('$salt:$password');
    var digest = sha256.convert(bytes);

    for (var i = 1; i < _iterations; i++) {
      digest = sha256.convert([...digest.bytes, ...utf8.encode(salt)]);
    }

    return digest.toString();
  }

  static bool verifyPassword({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    return hashPassword(password, salt) == expectedHash;
  }
}

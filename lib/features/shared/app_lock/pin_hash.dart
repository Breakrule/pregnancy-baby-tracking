import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 is intentional for this threat model: a 6-digit PIN has
/// 1M candidates, so an attacker with access to the app's sandbox could
/// brute-force any hash offline; the salt only defeats rainbow tables.
/// Upgrade path if ever needed: swap [hash] for argon2id, API unchanged.
class PinHash {
  PinHash._();

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  static String hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool verify(String pin, String salt, String expectedHash) {
    final actual = hash(pin, salt);
    // Constant-time comparison.
    if (actual.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}

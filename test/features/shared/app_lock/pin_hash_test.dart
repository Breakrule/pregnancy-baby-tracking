import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/features/shared/app_lock/pin_hash.dart';

void main() {
  test('same pin + salt hashes identically', () {
    final salt = PinHash.generateSalt();
    expect(PinHash.hash('1234', salt), PinHash.hash('1234', salt));
  });

  test('different salt produces different hash', () {
    final a = PinHash.generateSalt();
    final b = PinHash.generateSalt();
    expect(PinHash.hash('1234', a), isNot(PinHash.hash('1234', b)));
  });

  test('verify succeeds only for correct pin', () {
    final salt = PinHash.generateSalt();
    final hash = PinHash.hash('9876', salt);
    expect(PinHash.verify('9876', salt, hash), isTrue);
    expect(PinHash.verify('0000', salt, hash), isFalse);
  });
}

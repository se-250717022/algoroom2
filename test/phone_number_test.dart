import 'package:flutter_test/flutter_test.dart';
import 'package:roommate/features/authentication/domain/auth_repository.dart';

void main() {
  test('Normalizes Turkish mobile formats and international numbers', () {
    expect(normalizePhoneNumber('0532 123 45 67'), '+905321234567');
    expect(normalizePhoneNumber('5321234567'), '+905321234567');
    expect(normalizePhoneNumber('+90 (532) 123-45-67'), '+905321234567');
    expect(normalizePhoneNumber('+44 7911 123456'), '+447911123456');
  });

  test('Rejects incomplete or malformed input', () {
    for (final value in ['', '0532', '+012345678', '0532ABC4567']) {
      expect(normalizePhoneNumber(value), isNull);
    }
  });
}

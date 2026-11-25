abstract interface class AuthRepository {
  Stream<bool> get signedIn;
  Future<void> signInWithGoogle();
  Future<PhoneChallenge?> sendCode(String number);
  Future<void> signOut();
}

typedef PhoneChallenge = Future<void> Function(String code);

String? normalizePhoneNumber(String value) {
  var number = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
  if (RegExp(r'^05\d{9}$').hasMatch(number)) {
    number = '+90${number.substring(1)}';
  } else if (RegExp(r'^5\d{9}$').hasMatch(number)) {
    number = '+90$number';
  }
  return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number) ? number : null;
}

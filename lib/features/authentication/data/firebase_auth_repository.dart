import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';

const authEnabled = bool.fromEnvironment('ROOMMATE_AUTH');

final authRepositoryProvider = FutureProvider<AuthRepository?>((ref) async {
  if (!authEnabled) return null;
  if (!kIsWeb &&
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return null;
  }
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  if (Firebase.apps.isEmpty &&
      (apiKey.isEmpty ||
          appId.isEmpty ||
          senderId.isEmpty ||
          projectId.isEmpty ||
          (kIsWeb && authDomain.isEmpty))) {
    throw StateError('Firebase Auth configuration is missing');
  }
  final app = Firebase.apps.isEmpty
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: senderId,
            projectId: projectId,
            authDomain: kIsWeb ? authDomain : null,
          ),
        )
      : Firebase.app();
  return FirebaseAuthRepository(FirebaseAuth.instanceFor(app: app));
}, retry: (_, _) => null);

final signedInProvider = StreamProvider<bool>((ref) async* {
  final repository = await ref.watch(authRepositoryProvider.future);
  if (repository == null) {
    yield false;
    return;
  }
  yield* repository.signedIn;
}, retry: (_, _) => null);

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;
  Future<void>? _googleInitialization;

  @override
  Stream<bool> get signedIn =>
      _auth.authStateChanges().map((user) => user != null);

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    const serverClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    final google = GoogleSignIn.instance;
    await (_googleInitialization ??= google.initialize(
      clientId: iosClientId.isEmpty ? null : iosClientId,
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    ));
    final account = await google.authenticate();
    final token = account.authentication.idToken;
    if (token == null) throw StateError('Missing Google ID token');
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  }

  @override
  Future<PhoneChallenge?> sendCode(String number) async {
    if (kIsWeb) {
      final result = await _auth.signInWithPhoneNumber(number);
      return (code) async {
        await result.confirm(code);
      };
    }
    final pending = Completer<PhoneChallenge?>();
    var confirmingAutomatically = false;
    unawaited(
      _auth
          .verifyPhoneNumber(
            phoneNumber: number,
            timeout: const Duration(seconds: 60),
            verificationCompleted: (credential) async {
              if (pending.isCompleted || confirmingAutomatically) return;
              confirmingAutomatically = true;
              try {
                await _auth.signInWithCredential(credential);
                if (!pending.isCompleted) pending.complete(null);
              } catch (error, stack) {
                if (!pending.isCompleted) pending.completeError(error, stack);
              }
            },
            verificationFailed: (error) {
              if (!pending.isCompleted) pending.completeError(error);
            },
            codeSent: (verificationId, _) {
              if (pending.isCompleted || confirmingAutomatically) return;
              pending.complete((code) async {
                await _auth.signInWithCredential(
                  PhoneAuthProvider.credential(
                    verificationId: verificationId,
                    smsCode: code,
                  ),
                );
              });
            },
            codeAutoRetrievalTimeout: (_) {
              if (!pending.isCompleted && !confirmingAutomatically) {
                pending.completeError(
                  TimeoutException('Phone verification timed out'),
                );
              }
            },
          )
          .then<void>(
            (_) {},
            onError: (Object error, StackTrace stack) {
              if (!pending.isCompleted) pending.completeError(error, stack);
            },
          ),
    );
    return pending.future.timeout(
      const Duration(seconds: 75),
      onTimeout: () {
        if (!pending.isCompleted) pending.complete(null);
        throw TimeoutException('Phone verification timed out');
      },
    );
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialization != null) await GoogleSignIn.instance.signOut();
  }
}

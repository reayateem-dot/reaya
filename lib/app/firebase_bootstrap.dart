import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future<bool>? _firebaseInitialization;

Future<bool> initializeFirebase() =>
    _firebaseInitialization ??= _initializeFirebase();

Future<bool> _initializeFirebase() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return false;
  }

  // 1. Initialize Firebase first.
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 12));
  } on FirebaseException catch (error) {
    debugPrint(
      'Firebase initialization failed (${error.plugin}/${error.code}).',
    );
    return false;
  } on Object catch (error) {
    debugPrint('Firebase initialization failed (${error.runtimeType}).');
    return false;
  }

  // 2. Activate App Check immediately after Firebase initialization.
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseAppCheck.instance
          .activate(
            providerAndroid: kDebugMode
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
          )
          .timeout(const Duration(seconds: 8));
    } else {
      await FirebaseAppCheck.instance
          .activate(
            providerApple: kDebugMode
                ? const AppleDebugProvider()
                : const AppleDeviceCheckProvider(),
          )
          .timeout(const Duration(seconds: 8));
    }
  } on FirebaseException catch (error) {
    debugPrint(
      'Firebase App Check initialization failed '
      '(${error.plugin}/${error.code}).',
    );
  } on Object catch (error) {
    debugPrint(
      'Firebase App Check initialization failed '
      '(${error.runtimeType}).',
    );
  }

  // 3. Configure Firestore after App Check activation.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } on FirebaseException catch (error) {
    debugPrint(
      'Firestore initialization failed (${error.plugin}/${error.code}).',
    );
    return false;
  } on Object catch (error) {
    debugPrint('Firestore initialization failed (${error.runtimeType}).');
    return false;
  }

  return true;
}

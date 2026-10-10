// File generated for CLIMATWIN Firebase configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for CLIMATWIN.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDlTQ1AqZWmmRTLQ-ncHtenUU4_BLe8JaY',
    appId: '1:291514312791:web:201b7240fa339516dc1b12',
    messagingSenderId: '291514312791',
    projectId: 'invest-2-77a18',
    authDomain: 'invest-2-77a18.firebaseapp.com',
    storageBucket: 'invest-2-77a18.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlTQ1AqZWmmRTLQ-ncHtenUU4_BLe8JaY',
    appId: '1:291514312791:android:201b7240fa339516dc1b12',
    messagingSenderId: '291514312791',
    projectId: 'invest-2-77a18',
    storageBucket: 'invest-2-77a18.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDlTQ1AqZWmmRTLQ-ncHtenUU4_BLe8JaY',
    appId: '1:291514312791:ios:201b7240fa339516dc1b12',
    messagingSenderId: '291514312791',
    projectId: 'invest-2-77a18',
    storageBucket: 'invest-2-77a18.firebasestorage.app',
    iosBundleId: 'com.climatwin.climatwin_mobile',
  );
}

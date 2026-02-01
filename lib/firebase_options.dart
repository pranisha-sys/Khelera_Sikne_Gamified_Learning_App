import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured yet.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS is not configured yet.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6kTLz3w3MkbKm9a-EILgU9gpHQXsmXCc',
    appId: '1:175868452618:android:59931bfcdac72b4e0ca4f3',
    messagingSenderId: '175868452618',
    projectId: 'khelera-sikne',
    databaseURL: 'https://khelera-sikne-default-rtdb.firebaseio.com',
    storageBucket: 'khelera-sikne.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6kTLz3w3MkbKm9a-EILgU9gpHQXsmXCc',
    appId: '1:175868452618:ios:XXXXXXXXXXXXXX',
    // You need to get this from Firebase Console
    messagingSenderId: '175868452618',
    projectId: 'khelera-sikne',
    iosBundleId: 'com.example.kheleraSikne',
    databaseURL: 'https://khelera-sikne-default-rtdb.firebaseio.com',
    storageBucket: 'khelera-sikne.firebasestorage.app',
  );
}

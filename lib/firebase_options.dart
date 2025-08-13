// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform şu an sadece WEB, Android ve iOS için ayarlı.',
        );
    }
  }

  // --- WEB (Firebase Console'daki config değerlerin) ---
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqltNdKMSTVHs5IIV0rtcgFhMv-5BSUU',
    appId: '1:884446641689:web:9c75b4851dffd27415b488',
    messagingSenderId: '884446641689',
    projectId: 'fault-8506366',
    authDomain: 'fault-8506366.firebaseapp.com',
    storageBucket: 'fault-8506366.appspot.com',
    measurementId: 'G-56NB38CEZW',
  );

  // --- ANDROID (Firebase Console'daki config değerlerin) ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAqltNdKMSTVHs5IIV0rtcgFhMv-5BSUU',
    appId: '1:884446641689:android:9c75b4851dffd27415b488',
    messagingSenderId: '884446641689',
    projectId: 'fault-8506366',
    storageBucket: 'fault-8506366.appspot.com',
  );

  // --- iOS (Firebase Console'daki config değerlerin) ---
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqltNdKMSTVHs5IIV0rtcgFhMv-5BSUU',
    appId: '1:884446641689:ios:9c75b4851dffd27415b488',
    messagingSenderId: '884446641689',
    projectId: 'fault-8506366',
    storageBucket: 'fault-8506366.appspot.com',
    iosClientId: '884446641689-9c75b4851dffd27415b488.apps.googleusercontent.com',
    iosBundleId: 'com.seninfirma.faultReport',
  );
}

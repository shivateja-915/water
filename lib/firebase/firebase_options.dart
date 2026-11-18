// Default Firebase options extracted from android/app/google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQQcrdO0M1PlYz9feC-aPkKAWfdTp46pE',
    appId: '1:62302380022:android:d1df81f8f47181b77271d7',
    messagingSenderId: '62302380022',
    projectId: 'water-94c7d',
    storageBucket: 'water-94c7d.firebasestorage.app',
  );
}

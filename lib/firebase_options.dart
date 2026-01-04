// File generated from google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9ClMor1ekP9U8RtMpc-4SIuncBFZgRhE',
    appId: '1:422331829842:android:50228fc38e4c40990b198b',
    messagingSenderId: '422331829842',
    projectId: 'studytrack-53105',
    storageBucket: 'studytrack-53105.firebasestorage.app',
  );

  // iOS için Firebase Console'dan iOS app eklemeniz gerekiyor
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '422331829842',
    projectId: 'studytrack-53105',
    storageBucket: 'studytrack-53105.firebasestorage.app',
    iosBundleId: 'com.studytrack.app',
  );
}

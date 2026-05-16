

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC53JV-UlXRcqaYL2LhcxrYaagLO5IKb7o',
    appId: '1:507576412877:web:84c31c8a9b19544e195784',
    messagingSenderId: '507576412877',
    projectId: 'moodswall-ff79f',
    authDomain: 'moodswall-ff79f.firebaseapp.com',
    storageBucket: 'moodswall-ff79f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC53JV-UlXRcqaYL2LhcxrYaagLO5IKb7o',
    appId: '1:507576412877:android:84c31c8a9b19544e195784',
    messagingSenderId: '507576412877',
    projectId: 'moodswall-ff79f',
    storageBucket: 'moodswall-ff79f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
      apiKey: 'AIzaSyC53JV-UlXRcqaYL2LhcxrYaagLO5IKb7o',
      appId: '1:507576412877:ios:84c31c8a9b19544e195784',
      messagingSenderId: '507576412877',
      projectId: 'moodswall-ff79f',
      storageBucket: 'moodswall-ff79f.firebasestorage.app',
      iosBundleId: 'com.xz.moodwalls',
  );

  static const FirebaseOptions macos = FirebaseOptions(
      apiKey: 'AIzaSyC53JV-UlXRcqaYL2LhcxrYaagLO5IKb7o',
      appId: '1:507576412877:ios:84c31c8a9b19544e195784', 
      messagingSenderId: '507576412877',
      projectId: 'moodswall-ff79f',
      storageBucket: 'moodswall-ff79f.firebasestorage.app',
      iosBundleId: 'com.xz.moodwalls',
  );

}

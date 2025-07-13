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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyAUBAyRnT0XEoKLlv-9GAmxi6F12peZd7c',
    appId: '1:125433829660:web:ce46e499b2965d91ae02d9',
    messagingSenderId: '125433829660',
    projectId: 'rsunfv',
    authDomain: 'rsunfv.firebaseapp.com',
    storageBucket: 'rsunfv.firebasestorage.app',
    measurementId: 'G-CFPRNL67KK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUzuq5yve35h1c66Jl9Mj48dL8MUQEwRM',
    appId: '1:125433829660:android:63b2fee2065baf09ae02d9',
    messagingSenderId: '125433829660',
    projectId: 'rsunfv',
    storageBucket: 'rsunfv.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAUBAyRnT0XEoKLlv-9GAmxi6F12peZd7c',
    appId: '1:125433829660:web:58d9d297c11dab77ae02d9',
    messagingSenderId: '125433829660',
    projectId: 'rsunfv',
    authDomain: 'rsunfv.firebaseapp.com',
    storageBucket: 'rsunfv.firebasestorage.app',
    measurementId: 'G-9EXMWTLDC4',
  );
}

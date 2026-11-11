import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Uses configuration matching existing NOTEShub Next.js application.
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
    apiKey: 'AIzaSyBHe5Kff_11bMVCkIzAkF6XjXHxb8wGxA0',
    appId: '1:243008726342:web:52271db2600a071f7a3147',
    messagingSenderId: '243008726342',
    projectId: 'smart-college-notes',
    authDomain: 'smart-college-notes.firebaseapp.com',
    storageBucket: 'smart-college-notes.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBHe5Kff_11bMVCkIzAkF6XjXHxb8wGxA0',
    appId: '1:243008726342:android:52271db2600a071f7a3147',
    messagingSenderId: '243008726342',
    projectId: 'smart-college-notes',
    storageBucket: 'smart-college-notes.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBHe5Kff_11bMVCkIzAkF6XjXHxb8wGxA0',
    appId: '1:243008726342:ios:52271db2600a071f7a3147',
    messagingSenderId: '243008726342',
    projectId: 'smart-college-notes',
    storageBucket: 'smart-college-notes.appspot.com',
  );
}

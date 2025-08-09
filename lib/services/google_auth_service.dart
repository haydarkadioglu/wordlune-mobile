import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google ile giriş yap
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Web platformu için
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        return await _auth.signInWithPopup(googleProvider);
      }
      
      // Mobil platformlar için
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Kullanıcı giriş işlemini iptal etti
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw Exception('Google ile giriş yapılamadı: ${e.toString()}');
    }
  }

  // Google hesabından çıkış yap
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Google Sign-Out Error: $e');
      throw Exception('Çıkış yapılamadı: ${e.toString()}');
    }
  }

  // Mevcut kullanıcının Google hesabı ile bağlantılı olup olmadığını kontrol et
  static bool isSignedInWithGoogle() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    return user.providerData.any((provider) => provider.providerId == 'google.com');
  }

  // Kullanıcı bilgilerini al
  static User? get currentUser => _auth.currentUser;

  // Auth state değişikliklerini dinle
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}

import 'package:chittychatty/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants.dart';
import 'user_service.dart';

class AuthService {
  final _firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User> userStream() => _firebaseAuth.authStateChanges();

  Future<String> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return null;
    } catch (e) {
      return e.message;
    }
  }

  Future<String> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) async {
        final appUser = AppUser(
            name: name,
            email: email,
            uid: value.user.uid,
            profilePic: kDefaultProfilePic);
        await UserService().addUserToDatabase(appUser: appUser);
      });
      return null;
    } catch (e) {
      return e.message;
    }
  }

  Future googleSignIn() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      } else {
        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _firebaseAuth.signInWithCredential(credential);
      }
    } catch (e) {
      return e.message;
    }
  }

  Future signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      return e.message;
    }
  }
}

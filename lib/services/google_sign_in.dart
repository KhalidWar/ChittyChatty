import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleSignInProvider =
    ChangeNotifierProvider((ref) => GoogleSignInStateManager());

class GoogleSignInStateManager extends ChangeNotifier {
  final _googleSignIn = GoogleSignIn();

  bool _isLoading;

  get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future signIn() async {
    isLoading = true;

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      isLoading = false;
      return null;
    } else {
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print(credential.accessToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
      isLoading = false;
    }
  }

  Future signOut() async {
    await _googleSignIn.signOut();
    FirebaseAuth.instance.signOut();
  }
}

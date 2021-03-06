import 'package:chittychatty/screens/authentication/initial_screen.dart';
import 'package:chittychatty/state_management/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';

final authStateManager = ChangeNotifierProvider((ref) => AuthStateManager());

class AuthStateManager extends ChangeNotifier {
  String _email, _password, _error, _name;
  bool _isLoading;

  get email => _email;
  get password => _password;
  get name => _name;
  get error => _error;
  get isLoading => _isLoading;

  void _setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String value) {
    _error = value;
  }

  void setEmail(String input) {
    _email = input;
  }

  void setPassword(String input) {
    _password = input;
  }

  void setName(String input) {
    _name = input;
    notifyListeners();
  }

  void signIn(BuildContext context, GlobalKey<FormState> formKey) {
    _setError(null);
    if (formKey.currentState.validate()) {
      _setIsLoading(true);
      context
          .read(authServiceProvider)
          .signInWithEmailAndPassword(_email, _password)
          .then((value) {
        _setIsLoading(false);
        _setError(value);
      }).catchError((error, stackTrace) => _setError(error));
    }
  }

  void googleSignIn(BuildContext context) {
    _setIsLoading(true);
    context.read(authServiceProvider).googleSignIn().then((value) {
      _setIsLoading(false);
      _setError(value);
    }).catchError((error, stackTrace) => _setError(error));
  }

  void signUp(BuildContext context, GlobalKey<FormState> formKey) {
    //todo fix app is stuck on loading after successful sign up
    _setError(null);
    if (formKey.currentState.validate()) {
      _setIsLoading(true);
      context
          .read(authServiceProvider)
          .signUpWithEmailAndPassword(_name, _email, _password)
          .then((value) {
        _setIsLoading(false);
        _setError(value);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => InitialScreen()));
      }).catchError((error, stackTrace) => _setError(error));
    }
  }
}

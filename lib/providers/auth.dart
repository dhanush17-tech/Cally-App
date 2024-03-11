import 'package:ai_calendar_app/host.dart';
import 'package:ai_calendar_app/providers/aiFunctions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class AuthProvider with ChangeNotifier {
  String _accessToken = "";
  String _refreshToken = "";
  String displayName = "";

  String get accessToken => _accessToken;
  String get refreshToken => _refreshToken;

  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
      "https://www.googleapis.com/auth/calendar.readonly"
    ],
  );

  Future<void> signOut() {
    return auth.signOut();
  }

  checkIfSignedIn() {
    return auth.currentUser != null;
  }

  Future<Map<String, dynamic>> autoSignIn(BuildContext context) async {
    try {
      GoogleSignInAuthentication? googleAuth;
      // Attempt silent sign in first
      final GoogleSignInAccount? googleUser =
          await googleSignIn.signInSilently();

      if (googleUser != null) {
        googleAuth = await googleUser.authentication;
      } else {
        // Perform interactive sign in
        final GoogleSignInAccount? googleUserInteractive =
            await googleSignIn.signIn();
        if (googleUserInteractive != null) {
          googleAuth = await googleUserInteractive.authentication;
        }
      }

      if (googleAuth != null && googleAuth.accessToken != null) {
        _accessToken = googleAuth.accessToken!;
        _refreshToken =
            googleAuth.idToken ?? ''; // refreshToken is usually the idToken
        notifyListeners();
        final UserCredential userCredential = await auth.signInWithCredential(
          GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          ),
        );

        displayName = userCredential.user?.displayName ?? '';
        notifyListeners();
      }
      // if (_refreshToken == "") {
      //   // final response = Dio().post("${apiBaseUrl}/tokens",data: {
      //   //   "accessToken": _accessToken,
      //   // });
      //   // response.then((value) {
      //   //   _accessToken = value.data["accessToken"];
      //   //   _refreshToken = value.data["refreshToken"];
      //   //   notifyListeners();
      //   // });
      //   final googleUser = await googleSignIn.signIn();

      //   final auth = await googleUser!.authentication;
      //   _refreshToken = auth.idToken!;
      //   _accessToken = auth.accessToken!;

      //   notifyListeners();
      // }
      return {
        "accessToken": _accessToken,
        'refreshToken': _refreshToken,
      };
    } catch (error) {
      print("Error during sign in: $error");
      // Handle the error, possibly by showing an error message to the user
      return {};
    }
  }
}

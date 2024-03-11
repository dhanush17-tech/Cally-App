import 'dart:convert';

import 'package:ai_calendar_app/providers/aiFunctions.dart';
import 'package:ai_calendar_app/providers/auth.dart';
import 'package:ai_calendar_app/views/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:provider/provider.dart';

class SignOut extends StatefulWidget {
  const SignOut({super.key});

  @override
  State<SignOut> createState() => _SignOutState();
}

class _SignOutState extends State<SignOut> {
  bool isLoadin = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("test")
                  .doc("1")
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snap.hasData) {
                  return snap.data!["isTestUser"] == true
                      ? Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final String name = await FlutterNativeTimezone
                                  .getLocalTimezone();

                              Provider.of<AIFunctions>(context, listen: false)
                                  .setTestUser(true);
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => HomeScreen(
                                            isSignedIn: true,
                                            access_token: "",
                                            refresh_token: "",
                                            isTestUser: true,
                                            timezoneName: name,
                                          )),
                                  (route) => false);
                            },
                            child: isLoadin
                                ? Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: CircularProgressIndicator(),
                                  )
                                : Text('Sign in Anonymously'),
                          ),
                        )
                      : Container();
                } else {
                  return Center(
                    child: Text("No Data"),
                  );
                }
              }),
          SizedBox(
            height: 20,
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false)
                    .autoSignIn(context)
                    .then((value) async {
                  if (Provider.of<AuthProvider>(context, listen: false)
                          .auth
                          .currentUser !=
                      null) {
                    final String name =
                        await FlutterNativeTimezone.getLocalTimezone();
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (c) => HomeScreen(
                                  isSignedIn: true,
                                  access_token: value["accessToken"],
                                  refresh_token: value["refreshToken"],
                                  isTestUser: false,
                                  timezoneName: name,
                                )),
                        (route) => false);
                  }
                });
              },
              child: isLoadin
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(),
                    )
                  : Text('Sign In with Google'),
            ),
          ),
        ],
      ),
    );
  }
}

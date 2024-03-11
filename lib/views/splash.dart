import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ai_calendar_app/providers/aiFunctions.dart';
import 'package:ai_calendar_app/providers/auth.dart';
import 'package:ai_calendar_app/views/home.dart';
import 'package:ai_calendar_app/views/signOut.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);

    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    navigateToHome();
  }

  Future<void> navigateToHome() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait a bit for the app to initialize
    await Future.delayed(const Duration(seconds: 2));

    // Now check the sign-in status
    bool signedIn = authProvider.checkIfSignedIn();
    final String name = await FlutterNativeTimezone.getLocalTimezone();
    print(name);
    // If signed in, ensure we have an accessToken by calling autoSignIn
    if (signedIn) {
      // This will refresh tokens if necessary and ensure they're not empty
      await authProvider.autoSignIn(context).then((value) {
        // Double check accessToken after autoSignIn completes
        if (value["accessToken"] != "") {
          // Navigate to HomeScreen if accessToken is available
          Navigator.pushAndRemoveUntil(
              context,
              PageTransition(
                  isIos: true,
                  duration: const Duration(milliseconds: 375),
                  type: PageTransitionType.size,
                  alignment: Alignment.center,
                  child: HomeScreen(
                    isSignedIn: true,
                    access_token: value["accessToken"],
                    refresh_token: value["refreshToken"],
                    timezoneName: name,
                  )),
              (r) => false);
          Provider.of<AIFunctions>(context, listen: false)
              .setAuthTokens(value["accessToken"], value["refreshToken"]);
        } else {
          Navigator.pushAndRemoveUntil(
              context,
              PageTransition(
                  isIos: true,
                  duration: const Duration(milliseconds: 375),
                  type: PageTransitionType.size,
                  alignment: Alignment.center,
                  child: SignOut()),
              (r) =>
                  false); // This might involve navigating to a sign-in screen or showing an error
        }
      });
    } else {
      // Navigate to SignOut (or sign-in screen) if not signed in
      Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
              isIos: true,
              duration: const Duration(milliseconds: 375),
              type: PageTransitionType.size,
              alignment: Alignment.center,
              child: SignOut()),
          (r) => false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/icon/c.png',
                height: 200,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, bottom: 10),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return ShaderMask(
                      child: child,
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ColorTween(begin: Colors.blue, end: Colors.green)
                                .lerp(_animation.value)!,
                            ColorTween(
                                    begin: Colors.purpleAccent,
                                    end: Colors.yellow)
                                .lerp(_animation.value)!,
                          ],
                        ).createShader(bounds);
                      },
                    );
                  },
                  child: Image.asset(
                    'assets/icon/star.png',
                    height: 150,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

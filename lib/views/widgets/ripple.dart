import 'dart:math';
import 'dart:ui';

import 'package:ai_calendar_app/providers/aiFunctions.dart';
import 'package:ai_calendar_app/providers/auth.dart' as auth;
import 'package:ai_calendar_app/views/widgets/chatScreen.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget chatPopup(BuildContext context, AnimationController animationController,
    Animation<Size>? sizeAnimation, String accessToken, String refreshToken) {
  if (sizeAnimation == null) {
    return SizedBox(); // or some placeholder widget
  }
  final _formKey = GlobalKey<FormState>();
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  var maxScreenWidthForBlur = screenHeight; // Adjust as needed
  final double blurAmount = max(0.0,
      min(10.0, (sizeAnimation.value.width / maxScreenWidthForBlur) * 10.0));
  final radius = (sizeAnimation.value.width / maxScreenWidthForBlur) * 10.0;

  return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus();
    },
    child: Consumer<AIFunctions>(builder: (context, aiFunctions, child) {
      return AnimatedBuilder(
          animation: sizeAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: Container(
                      width: screenWidth,
                      height: screenHeight,
                      padding: EdgeInsets.all(12),
                      child: SafeArea(
                        child: Center(
                            child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: FloatingActionButton(
                                  shape: CircleBorder(),
                                  child: Icon(
                                    Icons.close_rounded,
                                  ),
                                  backgroundColor: Colors.blue.withOpacity(0.5),
                                  onPressed: () {
                                    aiFunctions.stopListening();

                                    animationController.reverse();
                                  }),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: TextField(
                                focusNode: aiFunctions.focusNode,
                                controller: aiFunctions.controller,
                                textInputAction: TextInputAction.go,
                                maxLines: null,
                                onTap: () {
                                  aiFunctions.stopListening();
                                },
                                onEditingComplete: () {
                                  aiFunctions.focusNode.unfocus();
                                  aiFunctions.processSpeechInput(
                                      animationController,
                                      context,
                                      Provider.of<auth.AuthProvider>(context,
                                              listen: false)
                                          .auth
                                          .currentUser!
                                          .uid,
                                      accessToken,
                                      refreshToken);
                                },
                                decoration: InputDecoration(
                                    hintText: "Tap to edit text...",

                                    //no border
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    fillColor: Colors.transparent),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            );
          });
    }),
  );
}

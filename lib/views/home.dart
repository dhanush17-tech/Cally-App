import 'dart:convert';
import 'dart:math';

import 'package:ai_calendar_app/notificationController.dart';
import 'package:ai_calendar_app/views/journalHome.dart';
import 'package:ai_calendar_app/views/signOut.dart';
import 'package:ai_calendar_app/views/widgets/ripple.dart';
import 'package:animate_do/animate_do.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_neat_and_clean_calendar/neat_and_clean_calendar_event.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gif/gif.dart';
import "package:intl/intl.dart";
import 'package:ai_calendar_app/providers/aiFunctions.dart';
import 'package:ai_calendar_app/providers/stateProvider.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:ai_calendar_app/providers/auth.dart' as auth;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'widgets/date.dart';

class HomeScreen extends StatefulWidget {
  final bool isSignedIn;
  final String access_token;
  final String refresh_token;
  final String timezoneName;
  final bool isTestUser;

  HomeScreen({
    Key? key,
    required this.isSignedIn,
    required this.access_token,
    required this.refresh_token,
    this.isTestUser = false,
    required this.timezoneName,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  @override
  void dispose() {
    AIFunctions(widget.access_token, widget.refresh_token, widget.timezoneName)
        .pulseController
        .dispose();
    AIFunctions(widget.access_token, widget.refresh_token, widget.timezoneName)
        .scrollController
        .dispose();
    _rippleAnimationController.dispose();
    AIFunctions(widget.access_token, widget.refresh_token, widget.timezoneName)
        .removeListener(AIFunctions(
                widget.access_token, widget.refresh_token, widget.timezoneName)
            .handleFocusChange);
    AIFunctions(widget.access_token, widget.refresh_token, widget.timezoneName)
        .focusNode
        .dispose();
    AIFunctions(widget.access_token, widget.refresh_token, widget.timezoneName)
        .throttle!
        .cancel();
    Provider.of<AIFunctions>(context, listen: false).pulseController.dispose();
    super.dispose();
  }

  late AnimationController _rippleAnimationController;
  Animation<Size>? _sizeAnimation; // Made nullable to ensure safe access
  late Animation<double> _opacityAnimation;

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Provider.of<AIFunctions>(context, listen: false).getCurrentTimeZone();
    initailizeNotifications();
    _rippleAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure the scroll controller is initialized here or earlier in your code
      await Provider.of<AIFunctions>(context, listen: false).fetchEvents(
        widget.isTestUser
            ? ""
            : Provider.of<auth.AuthProvider>(context, listen: false)
                .auth
                .currentUser!
                .uid,
        widget.access_token,
        widget.refresh_token,
      );
      Provider.of<AIFunctions>(context, listen: false).getTodaysSummary(
          Provider.of<auth.AuthProvider>(context, listen: false).accessToken,
          widget.timezoneName);

      // Now attach the listener
      // Assuming you're animating to full screen, calculate the diagonal length
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _sizeAnimation = Tween<Size>(
          begin: Size.zero,
          end: Size(screenSize.width, screenSize.height),
        ).animate(
          CurvedAnimation(
            parent: _rippleAnimationController,
            curve: Curves.fastOutSlowIn,
          ),
        );
        _opacityAnimation =
            Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _rippleAnimationController,

          curve: Curves.easeIn, // Adjust the curve to suit your needs
        ));
      });
      // You might need to call setState here if necessary
    });

    final aiFunctions = Provider.of<AIFunctions>(context, listen: false);
    aiFunctions.initPulseController(this);

    // Attach the listener

    WidgetsFlutterBinding.ensureInitialized();
    AIFunctions(widget.access_token, widget.refresh_token, widget.timezoneName)
        .focusNode
        .addListener(AIFunctions(
                widget.access_token, widget.refresh_token, widget.timezoneName)
            .handleFocusChange);
    Provider.of<AIFunctions>(context, listen: false).scheduleNotifications();
  }

  void _scrollDown(AIFunctions aiFunctions) {
    // Ensure the ScrollController is attached to a scroll view.
    if (aiFunctions.scrollController.hasClients) {
      aiFunctions.scrollController.animateTo(
        aiFunctions.scrollController.position.maxScrollExtent + 120,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future initailizeNotifications() async {
    await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'alerts',
            channelName: 'Alerts',
            channelDescription: 'Notification Reminder as alerts',
            playSound: true,
            onlyAlertOnce: true,
          ),
          NotificationChannel(
            channelKey: 'daily_reminder',
            channelName: 'Daily Reminder',
            channelDescription: 'Notification for daily reminders',
            playSound: true,
            onlyAlertOnce: true,
          )
        ],
        debug: true);

    bool isNotificationEnabled =
        await AwesomeNotifications().isNotificationAllowed();
    if (!isNotificationEnabled) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    AwesomeNotifications().setListeners(
        onActionReceivedMethod: (ReceivedAction receivedAction) async {
          return NotificationController.onActionReceivedMethod(
              receivedAction, context);
        },
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod);
  }

  void _scrollUp(AIFunctions aiFunctions) {
    if (aiFunctions.scrollController.hasClients) {
      aiFunctions.scrollController.animateTo(
        aiFunctions.scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<String> sample() async {
    await Future.delayed(Duration(seconds: 2), () async {
      return "It's gonna be great!!! You are gonna be amazing man.. keep going!";
    });
    return "It's gonna be great!!! You are gonna be amazing man.. keep going!";
  }

  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 20) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiFunctions = Provider.of<AIFunctions>(
      context,
    );
    // aiFunctions.setAuthTokens(widget.access_token, widget.refresh_token);
    final authProvider = Provider.of<auth.AuthProvider>(
      context,
    );
    // print(authProvider.accessToken);
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          Padding(
              padding: EdgeInsets.only(
                left: 15.0,
                right: 15,
              ),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                controller: aiFunctions.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: min(
                              MediaQuery.of(context).size.height * 0.055, 50),
                        ),
                        AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                verticalOffset: -100.0,
                                child: FadeInAnimation(
                                  child: widget,
                                ),
                              ),
                              children: [
                                if (MediaQuery.of(context).size.height <= 1000)
                                  SizedBox(
                                    height: 10,
                                  ),
                                // Greeting Message Row
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      //a circular container for the memoji
                                      // Container(
                                      //   alignment: Alignment.center,
                                      //   width: 50,
                                      //   height: 50,
                                      //   decoration: BoxDecoration(
                                      //     color: Colors.grey.withOpacity(0.1),
                                      //     shape: BoxShape.circle,
                                      //   ),
                                      //   child: Center(
                                      //       child: Text(
                                      //     "😎",
                                      //     style: Theme.of(context)
                                      //         .textTheme
                                      //         .headline4,
                                      //     textAlign: TextAlign.center,
                                      //   )),
                                      // ),
                                      GestureDetector(
                                        onTap: () async {
                                          aiFunctions.isTestUser == false
                                              ? await authProvider.signOut()
                                              : null;
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (c) => SignOut()),
                                              (route) => false);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: Colors.redAccent
                                                .withOpacity(0.3),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                  // key: ValueKey(_key),
                                                  radius: 20,
                                                  backgroundColor:
                                                      Colors.grey[200],
                                                  backgroundImage: NetworkImage(
                                                      aiFunctions.isTestUser
                                                          ? "https://p7.hiclipart.com/preview/355/848/997/computer-icons-user-profile-google-account-photos-icon-account.jpg"
                                                          : authProvider
                                                              .auth
                                                              .currentUser!
                                                              .photoURL!)),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Text("Sign Out",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText1
                                                      ?.copyWith(
                                                        color: Colors.redAccent,
                                                      )),
                                              SizedBox(
                                                width: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    JournalHome(
                                                      isTestUser:
                                                          widget.isTestUser,
                                                    )),
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  Colors.blue.withOpacity(0.5)),
                                          child: Icon(Icons.book_rounded),
                                        ),
                                      )
                                    ]),
                                SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "${getGreetingMessage()} ${aiFunctions.isTestUser ? "Test User" : authProvider.displayName.split(" ")[0]} !",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              fontSize: 25),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    //SUMMARY for the day container
                    AnimationLimiter(
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: -100.0,
                            child: FadeInAnimation(
                              child: widget,
                            ),
                          ),
                          children: [
                            // Greeting Message Row
                            AnimationLimiter(
                              child: Column(
                                children:
                                    AnimationConfiguration.toStaggeredList(
                                        duration:
                                            const Duration(milliseconds: 375),
                                        childAnimationBuilder: (widget) =>
                                            SlideAnimation(
                                              verticalOffset: 50.0,
                                              child: FadeInAnimation(
                                                child: widget,
                                              ),
                                            ),
                                        children: [
                                      aiFunctions.todaySummary == ""
                                          ? Shimmer.fromColors(
                                              enabled: true,
                                              child: Container(
                                                width: double.infinity,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15)),
                                              ),
                                              baseColor:
                                                  Colors.grey.withOpacity(0.5),
                                              highlightColor:
                                                  Colors.grey.withOpacity(0.2),
                                            )
                                          : AnimatedOpacity(
                                              opacity:
                                                  aiFunctions.todaySummary == ''
                                                      ? 0
                                                      : 1,
                                              duration:
                                                  Duration(milliseconds: 500),
                                              curve: Curves.easeIn,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10.0),
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Align(
                                                              alignment:
                                                                  Alignment
                                                                      .topLeft,
                                                              child: Markdown(
                                                                  onTapLink:
                                                                      (text,
                                                                          href,
                                                                          title) {
                                                                    launchUrlString(
                                                                        href!);
                                                                  },
                                                                  padding:
                                                                      EdgeInsets.all(
                                                                          0),
                                                                  data: aiFunctions
                                                                      .todaySummary,
                                                                  shrinkWrap:
                                                                      true,
                                                                  listItemCrossAxisAlignment:
                                                                      MarkdownListItemCrossAxisAlignment
                                                                          .start,
                                                                  physics:
                                                                      NeverScrollableScrollPhysics(),
                                                                  styleSheet:
                                                                      MarkdownStyleSheet(
                                                                          pPadding: EdgeInsets.all(
                                                                              0),
                                                                          textAlign: WrapAlignment
                                                                              .start,
                                                                          p: Theme.of(context)
                                                                              .textTheme
                                                                              .bodyText1
                                                                              ?.copyWith(
                                                                                fontWeight: FontWeight.w500,
                                                                                letterSpacing: 0.5,
                                                                              ))),
                                                            ),
                                                          ])),
                                                ),
                                              ),
                                            ),
                                    ]),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 30,
                    ),

                    // Container(
                    //     height: 110,
                    //     child: ListView.builder(
                    //       scrollDirection: Axis.horizontal,
                    //       itemCount: DateTime.now()
                    //               .add(Duration(days: 90))
                    //               .difference(DateTime.now()
                    //                   .subtract(Duration(days: 90)))
                    //               .inDays +
                    //           1,
                    //       itemBuilder: (context, index) {
                    //         DateTime _date = DateTime.now()
                    //             .subtract(Duration(days: 90))
                    //             .add(Duration(days: index));
                    //         bool _isSelected =
                    //             aiFunctions.selectedDate == _date;
                    //         int eventsCount = aiFunctions
                    //                 .eventsForSelectedDay(
                    //                     _date, widget.timezoneName)
                    //                 ?.length ??
                    //             0;

                    //         return DateItem(
                    //           key: ValueKey(""),
                    //           date: _date,
                    //           isSelected: _isSelected,
                    //           onDateTap: (DateTime selectedDate) {
                    //             // Logic to handle tap
                    //           },
                    //           eventCount: eventsCount,
                    //         );
                    //       },
                    //     )),

                    EasyInfiniteDateTimeLine(
                      dayProps: EasyDayProps(
                        activeDayStyle: DayStyle(decoration: BoxDecoration()),
                        height: 110,
                      ),
                      controller: EasyInfiniteDateTimelineController(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year,
                          DateTime.now().month + 3, DateTime.now().day),
                      focusDate: aiFunctions.selectedDate,
                      onDateChange: (selectedDate) async {
                        aiFunctions.setSelectedDate(selectedDate);

                        aiFunctions.getTodaysSummary(
                            widget.isTestUser
                                ? ""
                                : Provider.of<auth.AuthProvider>(context,
                                        listen: false)
                                    .auth
                                    .currentUser!
                                    .uid,
                            widget.timezoneName);
                        // Update your state to reflect the newly selected date
                      },
                      showTimelineHeader: false,
                      itemBuilder: (context, a, b, c, dateTime, isSelected) {
                        int maxDotsToShow = 4;
                        int eventsCount = aiFunctions
                            .eventsForSelectedDay(
                                dateTime, widget.timezoneName)!
                            .length;
                        List<Widget> dots = List<Widget>.generate(
                          min(eventsCount, maxDotsToShow),
                          (index) => Container(
                            margin: EdgeInsets.only(right: 5),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );

                        // If there are more events than the maxDotsToShow, add a '+ more' indicator
                        if (eventsCount > maxDotsToShow) {
                          dots.add(Text('+${eventsCount - maxDotsToShow} more',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2
                                  ?.copyWith(fontSize: 10)));
                        }

                        // Map<DateTime, int> dotsMap = {};

                        // // Loop through each event in the jsonEvents list
                        // for (var event in snap.data ?? {}) {
                        //   // Parse the event's start date as a DateTime object
                        //   DateTime eventDate =
                        //       DateTime.parse(event['startDate'])
                        //           .toLocal();

                        //   // If the date already exists in the map, increment its count, otherwise add it with a count of 1
                        //   if (dotsMap.containsKey(eventDate)) {
                        //     dotsMap[eventDate] =
                        //         dotsMap[eventDate]! + 1;
                        //   } else {
                        //     dotsMap[eventDate] = 1;
                        //   }
                        // }

                        return SingleChildScrollView(
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: aiFunctions.selectedDate == dateTime
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('EEE')
                                          .format(dateTime), // Short day name.
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    Text(
                                      dateTime.day.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    SizedBox(height: 5),
                                    Wrap(
                                      runSpacing: 5,
                                      alignment: WrapAlignment.center,
                                      runAlignment: WrapAlignment.center,
                                      children: dots.length == 0
                                          ? [
                                              Container(
                                                  padding:
                                                      EdgeInsets.only(right: 5),
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                  ))
                                            ]
                                          : dots,
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );

                        // }
                        //      else {
                        //       // Show a placeholder or message if there are no events
                        //       return Shimmer.fromColors(
                        //         highlightColor: Colors.grey.withOpacity(0.5),
                        //         baseColor: Theme.of(context).backgroundColor,
                        //         child: Container(
                        //             alignment: Alignment.center,
                        //             padding: EdgeInsets.all(10),
                        //             decoration: BoxDecoration(
                        //               borderRadius: BorderRadius.circular(10),
                        //               color: Colors.grey.withOpacity(0.2),
                        //             )),}

                        // );
                      },
                    ),

                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Container(
                          child: ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: EdgeInsets.all(0),
                            itemCount: aiFunctions
                                .eventsForSelectedDay(aiFunctions.selectedDate,
                                    widget.timezoneName)
                                .length,
                            itemBuilder: (context, index) {
                              final todoListProvider = Provider.of<AIFunctions>(
                                  context,
                                  listen: false);
                              final list = aiFunctions.eventsForSelectedDay(
                                  aiFunctions.selectedDate,
                                  widget.timezoneName);
                              var event = list[index];
                              bool isCompleted = todoListProvider
                                      .eventIsDoneMap[event.metadata!['id']] ??
                                  false;
                              return AnimationLimiter(
                                child: AnimationConfiguration.staggeredList(
                                    position: index,
                                    child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          duration: Duration(milliseconds: 500),
                                          child: buildEventTile(
                                              event, isCompleted, aiFunctions),
                                        ))),
                              );
                            },
                          ),
                        )),

                    // MyCachingWidget(
                    //   aiFunctions: aiFunctions,
                    //   timezoneName: widget.timezoneName,
                    //   isTestUser: widget.isTestUser,
                    // ),
                    SizedBox(
                      height: 15,
                    ),
                    Consumer3<auth.AuthProvider, AIFunctions, LoadingState>(
                        builder: (context, authProvider, aiFunctions,
                            loadingState, child) {
                      return Column(
                        children: [
                          aiFunctions.messages.isEmpty
                              ? Align(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: Text(
                                      "Tell me to summarize your day or\nSetup an online meeting with hi@gmail.com",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText1
                                          ?.copyWith(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ))
                              : FadeIn(
                                  child: Hero(
                                      tag: "chatList",
                                      child: AnimatedList(
                                        physics: NeverScrollableScrollPhysics(),
                                        padding: EdgeInsets.all(0),
                                        key: aiFunctions.listKey,
                                        shrinkWrap: true,
                                        initialItemCount:
                                            aiFunctions.messages.length ?? 0,
                                        itemBuilder:
                                            (context, index, animation) {
                                          final curvedAnimation =
                                              CurvedAnimation(
                                            parent: animation,
                                            curve: Curves
                                                .easeInOut, // Use the easeIn curve
                                            // Optionally, you can specify a reverseCurve if needed
                                          );

                                          final msg =
                                              aiFunctions.messages[index];
                                          return SlideTransition(
                                            key: ValueKey(index),
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 1),
                                              end: Offset.zero,
                                            ).animate(curvedAnimation),
                                            child: Align(
                                              alignment: msg.isUserMessage
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              child: msg.isLoading
                                                  ? Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 20.0),
                                                      child: Shimmer.fromColors(
                                                        enabled: true,
                                                        child: Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width -
                                                              100,
                                                          height: 100,
                                                          decoration: BoxDecoration(
                                                              color:
                                                                  Colors.black,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20)),
                                                        ),
                                                        baseColor: Colors.grey
                                                            .withOpacity(0.5),
                                                        highlightColor: Colors
                                                            .grey
                                                            .withOpacity(0.2),
                                                      ),
                                                    )
                                                  : msg.isUserMessage
                                                      ? Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                      borderRadius: BorderRadius
                                                                          .circular(
                                                                              20),
                                                                      gradient:
                                                                          LinearGradient(
                                                                        // center: Alignment.center,
                                                                        // radius: 03,
                                                                        begin: Alignment
                                                                            .bottomLeft,
                                                                        end: Alignment
                                                                            .bottomLeft,
                                                                        stops: [
                                                                          0.0,
                                                                          1.0
                                                                        ],
                                                                        colors: [
                                                                          Theme.of(context)
                                                                              .colorScheme
                                                                              .inversePrimary
                                                                              .withOpacity(0.2),
                                                                          Theme.of(context)
                                                                              .colorScheme
                                                                              .inversePrimary
                                                                              .withOpacity(0.1),
                                                                        ],
                                                                      )),
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                horizontal: 20,
                                                                vertical: 10,
                                                              ),
                                                              constraints: BoxConstraints(
                                                                  maxWidth: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.7),
                                                              child: Container(
                                                                child:
                                                                    SelectableText(
                                                                  msg.text,
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyText1
                                                                      ?.copyWith(
                                                                          fontSize:
                                                                              15,
                                                                          fontWeight: FontWeight
                                                                              .w500,
                                                                          color:
                                                                              Theme.of(context).primaryColor!),
                                                                ),
                                                              )),
                                                        )
                                                      : Markdown(
                                                          data: msg.text,
                                                          selectable: true,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: 0,
                                                            vertical: 20,
                                                          ),
                                                          listItemCrossAxisAlignment:
                                                              MarkdownListItemCrossAxisAlignment
                                                                  .start,
                                                          onTapLink: (text,
                                                              href, title) {
                                                            launch(href!);
                                                          },
                                                          styleSheet:
                                                              MarkdownStyleSheet(),
                                                          physics:
                                                              NeverScrollableScrollPhysics(),
                                                          shrinkWrap: true,
                                                        ),
                                            ),
                                          );
                                        },
                                      ))),
                          SizedBox(
                            height: 80,
                          )
                        ],
                      );
                    }),

                    //scroll down to the bottom of the list show only of it is not in the max extent
                  ],
                ),
              )),
          AnimatedOpacity(
            opacity: _sizeAnimation == null ? 0.0 : 1,
            duration: Duration(milliseconds: 375),
            child: Consumer3<auth.AuthProvider, AIFunctions, LoadingState>(
                builder:
                    (context, authProvider, aiFunctions, loadingState, child) {
              return Stack(
                children: [
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height:
                            80, // Adjust the height to control the fade area
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Theme.of(context)
                                  .scaffoldBackgroundColor, // Assuming this is your background color
                              Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withOpacity(0), // Transparent
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: max(MediaQuery.of(context).viewPadding.top, 40)),
                      child: AnimatedOpacity(
                        opacity: 1,
                        duration: Duration(milliseconds: 375),
                        child: GestureDetector(
                          onTap: () {
                            _scrollUp(aiFunctions);
                          },
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                shape: BoxShape.circle),
                            child: Icon(Icons.arrow_upward_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 120.0),
                      child: AnimatedOpacity(
                        opacity: aiFunctions.showScrollDownButton ? 1 : 0,
                        duration: Duration(milliseconds: 375),
                        child: GestureDetector(
                          onTap: () {
                            _scrollDown(aiFunctions);
                          },
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                shape: BoxShape.circle),
                            child: Icon(Icons.arrow_downward_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height:
                            80, // Adjust the height to control the fade area
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .scaffoldBackgroundColor, // Assuming this is your background color
                              Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withOpacity(0), // Transparent
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _sizeAnimation == null ? 0 : 1,
                    duration: Duration(milliseconds: 375),
                    child: IgnorePointer(
                      ignoring: _sizeAnimation!.isCompleted == false,
                      child: AnimatedBuilder(
                        animation: _sizeAnimation!,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _opacityAnimation,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: chatPopup(
                                  context,
                                  _rippleAnimationController,
                                  _sizeAnimation,
                                  widget.access_token,
                                  widget.refresh_token),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                        padding: EdgeInsets.only(bottom: 0),
                        child: GestureDetector(
                            onTap: () async {
                              if (mounted) {
                                if (_sizeAnimation!.isCompleted &&
                                    aiFunctions.manuallyStopped == true) {
                                  aiFunctions.processSpeechInput(
                                      _rippleAnimationController,
                                      context,
                                      widget.isTestUser
                                          ? ""
                                          : Provider.of<auth.AuthProvider>(
                                                  context,
                                                  listen: false)
                                              .auth
                                              .currentUser!
                                              .uid,
                                      widget.access_token,
                                      widget.refresh_token);
                                  await aiFunctions.fetchEvents(
                                      widget.isTestUser
                                          ? ""
                                          : Provider.of<auth.AuthProvider>(
                                                  context,
                                                  listen: false)
                                              .auth
                                              .currentUser!
                                              .uid,
                                      widget.access_token,
                                      widget.refresh_token);
                                  await aiFunctions.loadTodoList();
                                } else if (_sizeAnimation!.isCompleted &&
                                    aiFunctions.manuallyStopped == false) {
                                  _rippleAnimationController.reverse();
                                } else {
                                  aiFunctions.startListening(
                                      _rippleAnimationController,
                                      context,
                                      widget.isTestUser
                                          ? ""
                                          : Provider.of<auth.AuthProvider>(
                                                  context,
                                                  listen: false)
                                              .auth
                                              .currentUser!
                                              .uid,
                                      widget.access_token,
                                      widget.refresh_token);
                                  _rippleAnimationController.forward();
                                }
                                Future.delayed(Duration(seconds: 2), () async {
                                  // aiFunctions.fetchEvents(
                                  //     Provider.of<auth.AuthProvider>(context,
                                  //             listen: false)
                                  //         .auth
                                  //         .currentUser!
                                  //         .uid);
                                  await aiFunctions.getTodaysSummary(
                                      Provider.of<auth.AuthProvider>(context,
                                              listen: false)
                                          .auth
                                          .currentUser!
                                          .uid,
                                      widget.timezoneName);
                                });
                              }
                            },
                            child: AnimatedBuilder(
                              animation: aiFunctions.amplitudeNotifier,
                              builder: (context, child) {
                                // Map the amplitude to a scale factor
                                // Assuming amplitude ranges from 0 to 1, adjust these values if needed
                                double normalizedAmplitude =
                                    aiFunctions.normalizeAmplitude(
                                        aiFunctions.amplitudeNotifier.value);

                                // Map the normalized amplitude to a scale factor (100 to 150 in this case)
                                double scale =
                                    mapAmplitudeToScale(normalizedAmplitude);

                                return Transform.scale(
                                  scale: scale / 200,
                                  child: Container(
                                    padding: EdgeInsets.all(0),
                                    height: 100, // Specify the height
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.7),
                                        width: 8,
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          "assets/gifs/ai.gif",
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ))),
                  ),
                ],
              );
            }),
          )
        ]));
  }

  Widget buildEventTile(
      NeatCleanCalendarEvent event, bool isCompleted, AIFunctions aiFunctions) {
    return GestureDetector(
      onTap: () {
        print(event.metadata!['meetingLink']);
        if (event.metadata!['meetingLink'] != "") {
          launchUrl(Uri.parse(event.metadata!['meetingLink']));
        }
        aiFunctions.setEventIsDone(event.metadata!['id'], !isCompleted);
      },
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Text(
                        event.summary,
                        style: Theme.of(context).textTheme.bodyText1,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCompleted)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 11, // Adjust the position as needed
                          child: Container(
                            height: 3, // Increase line thickness
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                  Stack(
                    children: [
                      Text(
                        "${event.metadata!['startDate']} - ${event.metadata!['endDate']}",
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                      if (isCompleted)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 7, // Adjust the position as needed
                          child: Container(
                            height: 3, // Increase line thickness
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            event.metadata!['meetingLink'] != ""
                ? Icon(Icons.videocam)
                : Container(
                    width: 30,
                    child: Checkbox(
                      value: isCompleted,
                      onChanged: (bool? newValue) {
                        aiFunctions.setEventIsDone(
                            event.metadata!['id'], newValue!);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

double mapAmplitudeToScale(double normalizedValue) {
  // Map normalized value (0 to 1) to your desired scale range (100 to 150)
  return 100 +
      (normalizedValue *
          50); // 100 is the minimum size, and 50 is the range size difference
}

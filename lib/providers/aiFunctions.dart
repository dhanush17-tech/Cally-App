import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ai_calendar_app/host.dart';
import 'package:ai_calendar_app/models/chatModel.dart';
import 'package:ai_calendar_app/providers/auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_neat_and_clean_calendar/neat_and_clean_calendar_event.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class AIFunctions with ChangeNotifier {
  List<NeatCleanCalendarEvent> _events = [];

  String accessToken = '';
  String refreshToken = '';

  FlutterTts flutterTts = FlutterTts();
  List<ChatMessage> _messages = [];

  setMessages(List<ChatMessage> messages) {
    _messages = messages;
    notifyListeners();
  }

  AIFunctions(String accessToken, String refreshToken, String timeZone) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    scrollController = ScrollController();
    // scrollController.addListener(_scrollListener);
    getCurrentTimeZone();
    _initializeTts();
    loadConversations(listKey);
    loadTodoList();
  }
  TextEditingController controller = TextEditingController();

  List jsonEvents = [];

  List<ChatMessage> get messages => _messages;

  List<NeatCleanCalendarEvent> get events => _events;

  Map<String, dynamic> _eventIsDoneMap = {};
  Map<String, dynamic> get eventIsDoneMap => _eventIsDoneMap;

  setEventIsDone(String id, bool isDone) {
    _eventIsDoneMap[id] = isDone;
    storeTodoList();
    notifyListeners();
  }

  Timer? throttle;

  void _scrollListener() {
    if (throttle?.isActive ?? false) return;

    throttle = Timer(const Duration(milliseconds: 00), () {
      bool isAtBottom = scrollController.offset >=
              scrollController.position.maxScrollExtent &&
          !scrollController.position.outOfRange;

      bool isAtTop = scrollController.offset <=
              scrollController.position.minScrollExtent &&
          !scrollController.position.outOfRange;

      showScrollDownButton = !isAtBottom;
      showScrollUpButton = !isAtTop;
    });
  }

  bool _isMicOn = false;
  bool get isMicOn => _isMicOn;
  get http => null;
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  setSelectedDate(DateTime value) {
    _selectedDate = value;
    notifyListeners();
  }

  void setAuthTokens(String accessToken, String refreshToken) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    notifyListeners();
  }

  String stripMarkdown(String markdown) {
    // Replace bold text with plain text
    markdown = markdown.replaceAll(RegExp(r'\*\*(.+?)\*\*'), '');
    markdown = markdown.replaceAll(RegExp('__(.+?)__'), '');

    // Replace italicized text with plain text
    markdown = markdown.replaceAll(RegExp('_(.+?)_'), '');
    markdown = markdown.replaceAll(RegExp(r'\*(.+?)\*'), '');

    // Replace strikethrough text with plain text
    markdown = markdown.replaceAll(RegExp('~~(.+?)~~'), '');

    // Replace inline code blocks with plain text
    markdown = markdown.replaceAll(RegExp('`(.+?)`'), '');

    // Replace code blocks with plain text
    markdown =
        markdown.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');
    markdown =
        markdown.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');

    // Remove links
    markdown = markdown.replaceAll(RegExp(r'\[(.+?)\]\((.+?)\)'), '');

    // Remove images
    markdown = markdown.replaceAll(RegExp(r'!\[(.+?)\]\((.+?)\)'), '');

    // Remove headings
    markdown =
        markdown.replaceAll(RegExp(r'^#+\s+(.+?)\s*$', multiLine: true), '');
    markdown = markdown.replaceAll(RegExp(r'^\s*=+\s*$', multiLine: true), '');
    markdown = markdown.replaceAll(RegExp(r'^\s*-+\s*$', multiLine: true), '');

    // Remove blockquotes
    markdown =
        markdown.replaceAll(RegExp(r'^\s*>\s+(.+?)\s*$', multiLine: true), '');

    // Remove lists
    markdown = markdown.replaceAll(
      RegExp(r'^\s*[\*\+-]\s+(.+?)\s*$', multiLine: true),
      '',
    );
    markdown = markdown.replaceAll(
      RegExp(r'^\s*\d+\.\s+(.+?)\s*$', multiLine: true),
      '',
    );

    // Remove horizontal lines
    markdown =
        markdown.replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), '');

    return markdown;
  }

  Future loadConversations(GlobalKey<AnimatedListState> listKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? convo = prefs.getString("convo");
    if (convo != null) {
      setMessages(List<ChatMessage>.from(List<ChatMessage>.generate(
          json.decode(convo).length,
          (index) => ChatMessage.fromJson(json.decode(convo)[index]))));
    }
    if (listKey.currentState != null) {
      listKey.currentState!.insertAllItems(0, _messages.length);
    }
    print(convo);
    notifyListeners();
  }

  Future saveConversations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        "convo",
        jsonEncode(List.generate(
            _messages.length, (index) => _messages[index].toJson())));
  }

  String timeZoneName = "";
  Future getCurrentTimeZone() async {
    final String name = await FlutterNativeTimezone.getLocalTimezone();
    timeZoneName = name;
    notifyListeners();
  }

  List<NeatCleanCalendarEvent> eventsForSelectedDay(
      DateTime date, String timezone) {
    tz.initializeTimeZones();
    final tz.Location currentLocation = tz.getLocation(timezone);
    final tz.TZDateTime selectedDateTz =
        tz.TZDateTime.from(date, currentLocation);

    List<NeatCleanCalendarEvent> filteredEvents = _events.where((event) {
      final tz.Location eventLocation =
          tz.getLocation(event.metadata!["timeZone"]);
      final tz.TZDateTime eventStartTz =
          tz.TZDateTime.from(event.startTime, eventLocation);
      final tz.TZDateTime eventStartLocal =
          tz.TZDateTime.from(eventStartTz, currentLocation);

      return DateUtils.dateOnly(eventStartLocal) ==
          DateUtils.dateOnly(selectedDateTz);
    }).toList();

    // Sort the filtered events by startDate
    filteredEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    return filteredEvents;
  }

  Future<void> _initializeTts() async {
    List<Object?> voices = await flutterTts.getVoices;
    List<String> jsonVoices = voices.map((e) => jsonEncode(e)).toList();
    List availVoices = jsonVoices.map((e) => jsonDecode(e)).toList();
    flutterTts.setVoice(
        {'name': availVoices[1]['name'], 'locale': availVoices[1]['locale']});
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
  }

  void textToSpeech(
      String text,
      AnimationController animationController,
      BuildContext context,
      String uid,
      String accessToken,
      String refreshToken) async {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
    if (_isMore == true) {
      animationController.reset();

      animationController.forward();
      startListening(
          animationController, context, uid, accessToken, refreshToken);
    }
  }

  void initializeTimeZones() => tz.initializeTimeZones();
  Future<String> convertDateTimeToUserTimezone(
      String dateTimeString, String inputTimeZone) async {
    // Initialize the timezone database
    tz.initializeTimeZones();
    final fromTzDate =
        tz.TZDateTime.parse(tz.getLocation(inputTimeZone), dateTimeString);
    final String currentTimeZone =
        await FlutterNativeTimezone.getLocalTimezone();
    final toDate =
        tz.TZDateTime.from(fromTzDate, tz.getLocation(currentTimeZone));

    DateFormat dateFormat = DateFormat('hh:mm a', 'en_US');
    String formattedDate = dateFormat.format(toDate);
    print("Formatted date: $formattedDate");

    return formattedDate;
  }

  Future<void> scheduleNotifications() async {
    // await fetchEvents(); // Ensure events are fetched.
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final scheduledEventsString =
        sharedPreferences.getString("alreadyScheduled") ?? "[]";
    print("this is scedw" + scheduledEventsString);
    List<String> alreadyScheduled =
        List<String>.from(jsonDecode(scheduledEventsString));
    print(_events);
    for (var event in _events) {
      String eventId = event.metadata?["id"] ?? "";

      // Check if the event ID is already scheduled to avoid rescheduling it.
      if (!alreadyScheduled.contains(eventId)) {
        DateTime startTime = event.startTime;
        String title = event.summary ??
            "Event"; // Provide a default title if none is present.

        // Calculate reminder time (10 minutes before the event).
        DateTime reminderTime = startTime.subtract(Duration(minutes: 10));

        // Generate a unique ID for the notification to avoid conflicts.
        int notificationId =
            DateTime.now().millisecondsSinceEpoch.remainder(100000);

        List<NotificationActionButton> buttons = [];
        if (event.metadata!["meetingLink"] != null &&
            event.metadata!["meetingLink"].isNotEmpty) {
          buttons.add(NotificationActionButton(
            key: 'OPEN_MEETING',
            label: 'Join Meeting',
            actionType: ActionType.Default,
          ));
        }

        // Schedule the notification.
        await AwesomeNotifications().createNotification(
          actionButtons: buttons,
          content: NotificationContent(
            id: notificationId,
            channelKey: 'alerts',
            title: title,
            body: "Let's get going ${["🚀", "😎", "🤘"][Random().nextInt(3)]}",
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar.fromDate(date: reminderTime),
        );

        // Add the event ID to the list of already scheduled events.
        alreadyScheduled.add(eventId);
      }
    }
    // Daily journal notification logic
    const dailyJournalNotificationId =
        "dailyJournalNotification"; // A unique ID for the daily notification
    if (!alreadyScheduled.contains(dailyJournalNotificationId)) {
      DateTime now = DateTime.now();
      DateTime endOfDay = DateTime(
          now.year, now.month, now.day, 20, 00); // Schedule for 23:59 today

      int notificationId = 100001; // A specific ID for this notification

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'daily_reminder',
          title: "Journal Time",
          body: "Let's write your journal Today 📖",
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: endOfDay),
      );

      alreadyScheduled.add(dailyJournalNotificationId); // Mark as scheduled
    }

    // Save the updated list of already scheduled events and the daily journal notification
    sharedPreferences.setString(
        "alreadyScheduled", jsonEncode(alreadyScheduled));
  }

  bool _showScrollDownButton = false;
  bool get showScrollDownButton => _showScrollDownButton;
  set showScrollDownButton(bool value) {
    _showScrollDownButton = value;
    notifyListeners();
  }

  bool _showScrollUpButton = false;
  bool get showScrollUpButton => _showScrollUpButton;
  set showScrollUpButton(bool value) {
    _showScrollUpButton = value;
    notifyListeners();
  }

  bool _isMore = false;
  bool get isMore => _isMore;
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  ScrollController scrollController = ScrollController();

  Future<void> sendMessage(
      String prompt,
      AnimationController sizeAnimation,
      BuildContext context,
      String uid,
      String accessToken,
      String refreshToken) async {
    int newIndex = _messages.length;
    ChatMessage newUserMessage = ChatMessage(text: prompt, isUserMessage: true);
    _messages.add(newUserMessage);
    listKey.currentState
        ?.insertItem(newIndex, duration: Duration(milliseconds: 500));

    int loadingIndex = _messages.length;
    ChatMessage loadingMessage =
        ChatMessage(text: 'Loading...', isUserMessage: false, isLoading: true);
    _messages.add(loadingMessage);
    listKey.currentState
        ?.insertItem(loadingIndex, duration: Duration(milliseconds: 500));

    sizeAnimation.reverse();
    notifyListeners();

    await scrollController.animateTo(
      scrollController.position.maxScrollExtent + 120,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    try {
      // Await the response from sendConversations
      String response = await sendConversations(prompt, 0, context, uid);
      _messages.removeAt(loadingIndex);
      listKey.currentState?.removeItem(
        loadingIndex,
        (context, animation) =>
            SizeTransition(sizeFactor: animation, child: Container()),
        duration: Duration(milliseconds: 250),
      );

      ChatMessage responseMessage =
          ChatMessage(text: response, isUserMessage: false, isLoading: false);
      _messages.add(responseMessage);
      listKey.currentState?.insertItem(_messages.length - 1,
          duration: Duration(milliseconds: 500));

      notifyListeners();
      await saveConversations(); // Ensure saveConversations is awaited if it's an asynchronous operation
      stopListening();

      await scrollController.animateTo(
        scrollController.position.maxScrollExtent + 120,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Clear the text field after sending the message
      controller.clear(); // Removed duplicate clear call
      manuallyStopped = false;
      textToSpeech(
          stripMarkdown(response),
          sizeAnimation,
          context,
          uid,
          accessToken,
          refreshToken); // Ensure textToSpeech is awaited if it's an asynchronous operation
      notifyListeners();
    } catch (error) {
      _messages.removeAt(loadingIndex);
      listKey.currentState?.removeItem(
        loadingIndex,
        (context, animation) =>
            SizeTransition(sizeFactor: animation, child: Container()),
        duration: Duration(milliseconds: 250),
      );

      // Handle errors by showing a generic message to the user
      ChatMessage errorMessage = ChatMessage(
        text: "Sorry, I couldn't process that. Please try again.",
        isUserMessage: false,
        isLoading: false,
      );
      _messages.add(errorMessage);
      listKey.currentState?.insertItem(_messages.length - 1,
          duration: Duration(milliseconds: 500));
      notifyListeners();
    }
    await fetchEvents(uid, accessToken, refreshToken);
    await loadTodoList();
  }

  stt.SpeechToText speech = stt.SpeechToText();

  // Initialize speech to text

  Future<void> initSpeechToText(
      AnimationController animationController,
      BuildContext context,
      String uid,
      String accessToken,
      String refreshToken) async {
    bool available = await speech.initialize(
      onStatus: (status) {
        print('Result listener status: $status');
        if (status == 'listening') {
          _isMicOn = true;
        } else if (status == 'done' && !manuallyStopped) {
          // Only process speech input if the listening ended naturally and not manually stopped
          _isMicOn = false;
          processSpeechInput(
              animationController, context, uid, accessToken, refreshToken);
        }
        notifyListeners(); // Notify listeners when there's a status change
      },
      onError: (errorNotification) {
        print('Error listener: $errorNotification');
        // Handle errors here if necessary
      },
    );
    if (!available) {
      print('The user has denied the use of speech recognition.');
      // Handle the case where speech recognition is not available or permissions are denied
    }
  }

  double _amplitude = 0.0;

  double get amplitude => _amplitude;

  late AnimationController pulseController;

  void initPulseController(TickerProvider vsync) {
    pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: vsync,
      lowerBound: 0.4,
      upperBound: 1.2,
    )..addListener(() {
        notifyListeners();
      });
  }

  ValueNotifier<double> amplitudeNotifier = ValueNotifier<double>(0.0);

  void updateAmplitude(double newAmplitude) {
    // Update the amplitude value
    amplitudeNotifier.value = newAmplitude;
  }

  // Start listening to speech
  void startListening(
      AnimationController animationController,
      BuildContext context,
      String uid,
      String accessToken,
      String refreshToken) async {
    flutterTts.stop(); // Stop any ongoing text-to-speech
    await initSpeechToText(animationController, context, uid, refreshToken,
        accessToken); // Ensure speech to text is initialized

    speech.listen(
      onSoundLevelChange: (level) {
        print(level);
        // Update amplitude based on sound level
        Future.delayed(Duration(seconds: 1), () {
          updateAmplitude(level);
        });
      },
      pauseFor: Duration(seconds: 2),
      onResult: (result) {
        controller.text = result.recognizedWords;
        _isMicOn = true;
        notifyListeners(); // Notify listeners of the new text
      },
    );
  }

  double normalizeAmplitude(double amplitude) {
    double normalizedAmplitude = ((amplitude + 2.5) / 5.0).clamp(0.0, 1.0);
    return normalizedAmplitude;
  }

  bool manuallyStopped = false; // Flag to track manual stop

  final FocusNode focusNode = FocusNode();
  bool isFocused = false; // To track text field focus state
  void handleFocusChange() {
    isFocused = focusNode.hasFocus;
    notifyListeners();
  }

  // Stop listening to speech manually
  void stopListening() {
    manuallyStopped = true; // Set the flag to indicate manual stop
    updateAmplitude(0);

    speech.stop();
    _isMicOn = false;
    notifyListeners(); // Notify listeners that microphone is off
  }

  void processSpeechInput(
      AnimationController animationController,
      BuildContext context,
      String uid,
      String accessToken,
      String refreshToken) {
    if (controller.text.isNotEmpty) {
      sendMessage(controller.text, animationController, context, uid,
          accessToken, refreshToken);
      controller.clear(); // Clear the controller after sending the message
    }
    animationController.reverse(); // Reverse the animation to its initial state
    stopListening();
    controller.text = ""; // Clear the controller text
    manuallyStopped = false;
    scheduleNotifications();
    notifyListeners();
  }

  Future<void> loadTodoList() async {
    final prefs = await SharedPreferences.getInstance();
    final todoList = prefs.getString('todoList');
    if (todoList != null) {
      _eventIsDoneMap = json.decode(todoList);
      notifyListeners();
    }
  }

  Future<void> storeTodoList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('todoList', json.encode(_eventIsDoneMap));
  }

  bool isTestUser = false;
  setTestUser(bool value) {
    isTestUser = value;
    notifyListeners();
  }

  Future<List<NeatCleanCalendarEvent>> fetchEvents(
      String uid, String accessToken, String refreshToken) async {
    try {
      final response = await Dio().post(
        '$apiBaseUrl/listEvents',
        data: {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          "isTestUser": isTestUser,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> eventsData = response.data['events'];
        jsonEvents = eventsData;

        // Use Future.wait to wait for all async operations to complete
        final tempEvents = await Future.wait(eventsData.map((eventData) async {
          if (_eventIsDoneMap[eventData['id']] == null) {
            _eventIsDoneMap[eventData['id']] = false;
          }

          DateTime startTime = DateTime.parse(eventData['startDate']);
          DateTime endTime = DateTime.parse(eventData['endDate']);

          final startTimeConverted = await convertDateTimeToUserTimezone(
              eventData['startDate'], eventData['timeZone']);
          final endTimeConverted = await convertDateTimeToUserTimezone(
              eventData['endDate'], eventData['timeZone']);

          return NeatCleanCalendarEvent(eventData['title'],
              description: eventData['description'],
              startTime: startTime,
              endTime: endTime,
              color: Colors.blue,
              isMultiDay: startTime.day != endTime.day,
              metadata: {
                'id': eventData['id'],
                'timeZone': eventData['timeZone'],
                "meetingLink": eventData['meetingLink'],
                "startDate": startTimeConverted,
                "endDate": endTimeConverted
              });
        }));

        storeTodoList();
        _events = tempEvents.cast<NeatCleanCalendarEvent>();
        notifyListeners();
        return _events; // Return the events
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      print("Error fetching events: $e");
      return []; // Return an empty list in case of error
    }
  }

  Future sendConversations(
      String prompt, int counter, BuildContext context, String uid) async {
    // await fetchEvents();

    try {
      int startIndex = _messages.length - 15;
      if (startIndex < 0) startIndex = 0; // Adjust start index if less than 0
      print(accessToken);

      final response = await Dio().post('$apiBaseUrl/chat', data: {
        "prompt": prompt,
        "timeZone": timeZoneName,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "isTestUser": isTestUser,
        "currentDate": DateTime.now().toIso8601String().replaceAll("Z", ""),
        "context": jsonEncode(
          List.generate(
            _messages.length -
                startIndex, // Adjust the number of items to generate based on the new start index
            (index) => _messages[startIndex + index]
                .toJson(), // Adjust the index to start from the corrected startIndex
          ),
        ),
        "events": jsonEvents,
      });

      print(response.data);

      if (response.statusCode == 200) {
        _isMore =
            response.data["action"] == "MORE"; // Refresh events after creation
        notifyListeners();

        print("This is ismore" + isMore.toString());
        return response.data["message"]; // Refresh events after creation
      } else {
        if (counter < 1) {
          await AuthProvider().autoSignIn(context);
          counter++;
          sendConversations(prompt, counter, context, uid);
        }
      }
    } catch (e) {
      print("Error creating event: $e");
      return "I'm sorry, I couldn't process that. Please try again.";
    }

    return "I'm sorry, I couldn't process that. Please try again.";
  }

  String todaySummary = "";

  Future getTodaysSummary(String uid, String timezone) async {
    final events = await eventsForSelectedDay(selectedDate, timezone);
    print("This is events" + events.toString());
    try {
      final response = await Dio().post("${apiBaseUrl}/todaysSummary", data: {
        "calendar": jsonEvents,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "currentSummary": todaySummary,
        "currentDate": selectedDate.month.toString() +
            "/" +
            selectedDate.day.toString() +
            "/" +
            selectedDate.year.toString(),
      });
      print(response.data);
      if (response.statusCode == 200) {
        if (response.data["message"] != "") {
          todaySummary = response.data["message"] ?? response.data;
        }
      } else {
        // todaySummary =
        //     "Oopps!! There seems to be an error here!! We'll fix it ASAP ☺️";
      }
    } catch (e) {
      print(e);
      // todaySummary =
      //     "Oopps!! There seems to be an error here!! We'll fix it ASAP ☺️";
    }
    notifyListeners();
  }
}

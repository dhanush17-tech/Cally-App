import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ai_calendar_app/host.dart';
import 'package:ai_calendar_app/models/journalModel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalProvider with ChangeNotifier {
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  final AudioRecorder soundRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Directory? appDirectory;
  String? path;
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  JournalProvider() {
    _requestPermission();
    _getDir();
  }

  Future<bool> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  List<JournalEntry> journalEntries = [];
  void setAudioPaths(List<String> paths) {
    notifyListeners();
  }

  Future<void> addJournalEntry(JournalEntry entry) async {
    journalEntries.add(entry);
    await saveJournalEntries();
  }

  Future<void> saveJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData =
        jsonEncode(journalEntries.map((e) => e.toMap()).toList());
    await prefs.setString('journalEntries', encodedData);
  }

  Future<List<JournalEntry>> loadJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    String? entriesString = prefs.getString('journalEntries');
    if (entriesString != null) {
      Iterable decoded = jsonDecode(entriesString);
      journalEntries = decoded.map((e) => JournalEntry.fromMap(e)).toList();
      print(journalEntries);
      return journalEntries.reversed.toList();
    }
    return [];
  }

  Future<String> getResponseFromRAG(
    String query,
     String uid
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedJournals = prefs.get("journalEntries");

    final response = await Dio().post(
      "${apiBaseUrl}/search",
      data: {
        "context": encodedJournals,
        "query": query,
        "userId": uid,
      },
    );
    print(response.data["message"]);
    return response.data["message"];
  }

  void updateJournalEntry(JournalEntry updatedEntry) {
    int index =
        journalEntries.indexWhere((entry) => entry.id == updatedEntry.id);
    if (index != -1) {
      journalEntries[index] = updatedEntry;
      saveJournalEntries(); // This will persist the updated entries list
      notifyListeners();
    } else {
      addJournalEntry(updatedEntry); // Adds new entry if it doesn't exist
    }
  }

  //delete journal
  void deleteJournalEntry(JournalEntry entry) {
    int index = journalEntries.indexWhere((entry) => entry.id == entry.id);
    if (index != -1) {
      journalEntries.removeAt(index);
      saveJournalEntries(); // This will persist the updated entries list
      notifyListeners();
    }
  }

  Future<void> _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory!.path}/recording.m4a";
    notifyListeners();
  }

  Future<List<String>> pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImages = await imagePicker.pickMultiImage();
    return pickedImages.map((e) => e.path).toList();
  }

  List<String> _audioPaths = [];

  Future<void> deleteRecording(String path) async {
    _audioPaths.remove(path);
    await File(path).delete();

    notifyListeners();
  }

  Future<String?> startOrStopRecording() async {
    final isRecording = await soundRecorder.isRecording();
    if (isRecording) {
      // Stop recording
      final path = await soundRecorder.stop();
      _isRecording = false;
      if (path != null) {
        _audioPaths.add(
            path); // Add the recording path only after recording is stopped
        notifyListeners();
        return path; // Return the path where recording was saved
      }
    } else {
      // Start recording
      final newPath =
          "${appDirectory!.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a";
      bool hasPermission = await soundRecorder.hasPermission();
      if (hasPermission) {
        await soundRecorder.start(RecordConfig(), path: newPath);
        _isRecording = true;
        // Don't add the path to _audioPaths here
      }
    }
    notifyListeners();

    return null; // Return null if no new recording was created
  }

  String? _currentlyPlayingPath;
  bool _isCurrentlyPlaying = false;

  String? get currentlyPlayingPath => _currentlyPlayingPath;
  bool get isCurrentlyPlaying => _isCurrentlyPlaying;

  Future<void> toggleAudioPlayback(String path) async {
    if (_currentlyPlayingPath == path && _isCurrentlyPlaying) {
      // If the same audio is currently playing, pause it.
      await _audioPlayer.pause();
      _isCurrentlyPlaying = false;
    } else {
      // If a different audio is selected or if nothing is playing, start the new audio.
      if (_currentlyPlayingPath != path) {
        // Stop any currently playing audio and load the new one.
        await _audioPlayer.stop(); // Ensure any previous audio is stopped.
        await _audioPlayer.play(DeviceFileSource(path)); // Load new audio file.
      }
      await _audioPlayer
          .play(DeviceFileSource(path)); // Play the loaded audio file.
      _currentlyPlayingPath = path; // Update the currently playing path.
      _isCurrentlyPlaying = true; // Set the playing status to true.
    }
    notifyListeners(); // Notify listeners to update UI if necessary.
  }

  @override
  void dispose() {
    soundRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

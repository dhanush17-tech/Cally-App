import 'dart:async';
import 'dart:io';
import 'package:ai_calendar_app/host.dart';
import 'package:ai_calendar_app/models/journalModel.dart';
import 'package:ai_calendar_app/models/journalModel.dart';
import 'package:ai_calendar_app/providers/aiFunctions.dart';
import 'package:ai_calendar_app/providers/auth.dart';
import 'package:ai_calendar_app/providers/journalProvider.dart';
import 'package:ai_calendar_app/views/journalHome.dart';
import 'package:ai_calendar_app/views/widgets/wave.dart';
import 'package:dio/dio.dart';

// import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class JournalScreen extends StatefulWidget {
  final JournalEntry journalEntry;

  JournalScreen(
    this.journalEntry,
  );

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  TextEditingController titleController = TextEditingController();

  TextEditingController descriptionController = TextEditingController();

  final FocusNode titleFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.journalEntry.title);
    descriptionController =
        TextEditingController(text: widget.journalEntry.content);

    titleController.addListener(() {
      _handleFocusChange(titleFocusNode);
    });
    descriptionController.addListener(() {
      _handleFocusChange(descriptionFocusNode);
    });

    WidgetsFlutterBinding.ensureInitialized();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _handleFocusChange(FocusNode focusNode) async {
    if (!focusNode.hasFocus) {
      print("called");
      await _saveForm();
      await addJournal();
    }
  }

  Future<void> _saveForm() async {
    // Proceed to save the journal entry only if it has content
    final updatedEntry = JournalEntry(
      id: widget.journalEntry.id,
      title: titleController.text.trim(),
      content: descriptionController.text.trim(),
      imagePaths: widget.journalEntry.imagePaths,
      audioPaths: widget.journalEntry.audioPaths,
    );
    Provider.of<JournalProvider>(context, listen: false)
        .updateJournalEntry(updatedEntry);
  }

  Future<void> addJournal() async {
    final journalEntry = JournalEntry(
      id: widget.journalEntry.id,
      title: titleController.text.trim(),
      content: descriptionController.text.trim(),
      imagePaths: widget.journalEntry.imagePaths,
      audioPaths: widget.journalEntry.audioPaths,
    );
    final response = await Dio().post("$apiBaseUrl/add", data: {
      "title": journalEntry.title,
      "content": journalEntry.content,
      "id": widget.journalEntry.id,
      "userId": Provider.of<AuthProvider>(context, listen: false)
          .auth
          .currentUser!
          .uid,
    });
    if (response.statusCode == 200) {
      print("Journal Entry added successfully");
    } else {
      print(response.statusCode);
    }
  }

  List<Widget> _buildTiles(List<String> imagePaths) {
    List<Widget> tiles = [];
    if (imagePaths.isNotEmpty) {
      tiles.add(StaggeredGridTile.count(
          crossAxisCellCount: 4,
          mainAxisCellCount: 2,
          child: AnimationConfiguration.staggeredGrid(
              position: 0,
              duration: const Duration(milliseconds: 375),
              columnCount: imagePaths.length,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(imagePaths[0]), fit: BoxFit.cover),
                  ),
                ),
              ))));
    }

    // Add smaller image tiles, leaving space for the "+2" overlay if needed
    int overlayIndex = imagePaths.length > 4 ? 4 : imagePaths.length;
    for (int i = 1; i < overlayIndex; i++) {
      tiles.add(StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: AnimationConfiguration.staggeredGrid(
              position: i,
              duration: const Duration(milliseconds: 375),
              columnCount: imagePaths.length,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(imagePaths[i]), fit: BoxFit.cover),
                  ),
                ),
              ))));
    }

    // Add the "+2" overlay tile if there are more than 4 images
    if (imagePaths.length > 4) {
      int additionalImages = imagePaths.length - 4;
      tiles.add(
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: GestureDetector(
            onTap: Provider.of<JournalProvider>(context).pickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Text(
                    '+$additionalImages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return tiles;
  }

  bool _isDeleting = false; // Flag to track delete action

  @override
  Widget build(BuildContext context) {
    // Add main image tile if it exists
    final journalProvider = Provider.of<JournalProvider>(context);

    journalProvider.setAudioPaths(widget.journalEntry.audioPaths);
    return PopScope(
      canPop: true,
      onPopInvoked: (d) async {
        if (!_isDeleting) {
          // Only call methods if not deleting
          await _saveForm();
          await addJournal();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(children: [
            SingleChildScrollView(
              // Enable scrolling when content is overflowing
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: titleController,
                          focusNode: titleFocusNode,
                          maxLines: 1,
                          decoration: InputDecoration(
                              hintText: 'Title',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: false,
                              fillColor: Colors.transparent),
                          style: TextStyle(
                              fontSize: 40.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 5),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 10),
                          child: GestureDetector(
                            onTap: () {
                              _isDeleting = true;
                              final journalProvider =
                                  Provider.of<JournalProvider>(context,
                                      listen: false);
                              journalProvider
                                  .deleteJournalEntry(widget.journalEntry);
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer,
                              ),
                              child: Icon(
                                Icons.delete_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final pickedImages =
                              await Provider.of<JournalProvider>(context,
                                      listen: false)
                                  .pickImage();

                          setState(() {
                            widget.journalEntry.imagePaths.addAll(pickedImages);
                            _saveForm();
                          });
                        },
                        child: Text('Add Image'),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final audioPath = await Provider.of<JournalProvider>(
                                  context,
                                  listen: false)
                              .startOrStopRecording();
                          if (audioPath != null) {
                            // A new recording was completed, update the journal entry and UI accordingly
                            setState(() {
                              widget.journalEntry.audioPaths.add(audioPath);
                              // Use a key to insert the item into AnimatedList
                              _listKey.currentState?.insertItem(
                                  widget.journalEntry.audioPaths.length - 1,
                                  duration: Duration(milliseconds: 375));
                            });
                            _saveForm(); // Ensure this method updates the entry in your provider
                          }
                        },
                        child: Text('Add Audio'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Display images in a staggered grid view

                  TextField(
                    controller: descriptionController,
                    focusNode: descriptionFocusNode,
                    maxLines: null,
                    decoration: InputDecoration(
                        hintText: 'Write your journal entry...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: false,
                        fillColor: Colors.transparent),
                    style: TextStyle(fontSize: 18.0),
                  ),
                  AnimatedList(
                    key: _listKey,
                    shrinkWrap: true,
                    initialItemCount: widget.journalEntry.audioPaths.length,
                    itemBuilder: (context, index, animation) {
                      // Wrap your ListTile or custom widget with FadeTransition and SizeTransition
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: ListTile(
                              leading: Icon(Icons.audiotrack),
                              title: Text('Recording ${index + 1}'),
                              trailing: buildTrailingWidget(index,
                                  animation), // Example function to build trailing widget
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  widget.journalEntry.imagePaths != []
                      ? AnimationConfiguration.staggeredList(
                          position: 0,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: StaggeredGrid.count(
                                crossAxisCount: 4,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                children:
                                    _buildTiles(widget.journalEntry.imagePaths),
                              ),
                            ),
                          ),
                        )
                      : Container(),

                  SizedBox(height: 10),
                ],
              ),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedOpacity(
                      opacity: journalProvider.isRecording ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 375),
                      curve: Curves.easeIn,
                      child: GestureDetector(
                          onTap: () async {
                            final audioPath =
                                await Provider.of<JournalProvider>(context,
                                        listen: false)
                                    .startOrStopRecording();
                            if (audioPath != null) {
                              // A new recording was completed, update the journal entry and UI accordingly
                              setState(() {
                                widget.journalEntry.audioPaths.add(audioPath);
                                // Use a key to insert the item into AnimatedList
                                _listKey.currentState?.insertItem(
                                    widget.journalEntry.audioPaths.length - 1,
                                    duration: Duration(milliseconds: 375));
                              });

                              _saveForm(); // Ensure this method updates the entry in your provider
                            }
                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer),
                            child: Icon(
                              Icons.stop,
                              color: Colors.white,
                            ),
                          )),
                    ))),
          ]),
        ),
      ),
    );
  }

  Widget buildTrailingWidget(int index, Animation<double> animation) {
    final journalProvider =
        Provider.of<JournalProvider>(context, listen: false);
    final path = widget.journalEntry.audioPaths[index];
    final isPlaying = journalProvider.currentlyPlayingPath == path &&
        journalProvider.isCurrentlyPlaying;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () => journalProvider.toggleAudioPlayback(path),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () {
            journalProvider.deleteRecording(path);

            setState(() {
              widget.journalEntry.audioPaths.removeAt(index);
              _saveForm();
              _listKey.currentState!.removeItem(
                index,
                (context, animation) => FadeTransition(
                  opacity:
                      CurvedAnimation(parent: animation, curve: Curves.easeIn),
                  child: SizeTransition(
                    sizeFactor: CurvedAnimation(
                        parent: animation, curve: Curves.easeIn),
                    child: ListTile(
                      leading: Icon(Icons.audiotrack),
                      title: Text('Recording ${index + 1}'),
                    ),
                  ),
                ),
                duration: Duration(milliseconds: 250),
              );
            });
          },
        ),
      ],
    );
  }
}

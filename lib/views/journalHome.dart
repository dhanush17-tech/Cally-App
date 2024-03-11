import 'dart:io';
import 'dart:math';

import 'package:ai_calendar_app/models/journalModel.dart';
import 'package:ai_calendar_app/providers/aiFunctions.dart';
import 'package:ai_calendar_app/providers/auth.dart';
import 'package:ai_calendar_app/providers/journalProvider.dart';
import 'package:ai_calendar_app/views/journalScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class JournalHome extends StatefulWidget {
  final bool isTestUser;
  JournalHome({this.isTestUser = false});
  @override
  State<JournalHome> createState() => _JournalHomeState();
}

class _JournalHomeState extends State<JournalHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    Provider.of<JournalProvider>(context, listen: false).loadJournalEntries();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    // Start the animation
    _animationController.forward();
  }

  TextEditingController _textEditingController = TextEditingController();
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _animationController.dispose();
  }

  String result = "";
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    Provider.of<JournalProvider>(context).loadJournalEntries();
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            // Enable scrolling when content is overflowing
            padding: EdgeInsets.symmetric(
              horizontal: min(MediaQuery.of(context).size.width * 0.041, 20),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: min(MediaQuery.of(context).size.height * 0.055, 50),
                ),
                if (MediaQuery.of(context).size.height <= 1000)
                  const SizedBox(
                    height: 15,
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Journals",
                      style: TextStyle(
                          fontSize: 40.0, fontWeight: FontWeight.bold),
                    ),
                    //create new journal button
                    GestureDetector(
                      onTap: () {
                        final journal = JournalEntry(
                            audioPaths: [],
                            title: "",
                            content: "",
                            imagePaths: [],
                            id: DateTime.now().toString());
                        final journalProvider = Provider.of<JournalProvider>(
                            context,
                            listen: false);
                        journalProvider.addJournalEntry(journal);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => JournalScreen(journal)),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.3)),
                        child: Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                FutureBuilder<List<JournalEntry>>(
                    future: Provider.of<JournalProvider>(context)
                        .loadJournalEntries(),
                    builder: (context, snapshot) {
                      return snapshot.data!.length == 0
                          ? Container(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.5,
                                    child: Image.asset(
                                      "assets/icon/nothing1.png",
                                      width: 350,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Text(
                                    "Start writing today!",
                                    style: TextStyle(
                                        fontSize: 30.0,
                                        color: Colors.grey.withOpacity(0.5),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          : AnimationLimiter(
                              child: ListView.separated(
                                separatorBuilder: (context, index) {
                                  return SizedBox(
                                    height: 20,
                                  );
                                },
                                physics: NeverScrollableScrollPhysics(),
                                padding:
                                    EdgeInsets.only(top: 0, left: 0, right: 0),
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (BuildContext context, int index) {
                                  List<StaggeredGridTile> tiles = [];
                                  print(snapshot.data![index].audioPaths);
                                  print(snapshot.data![index].imagePaths);

                                  // Add main image tile if it exists
                                  if (snapshot
                                      .data![index].imagePaths.isNotEmpty) {
                                    tiles.add(
                                      StaggeredGridTile.count(
                                        crossAxisCellCount: 4,
                                        mainAxisCellCount: 2,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.file(
                                              File(snapshot
                                                  .data![index].imagePaths[0]),
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                    );
                                  }

                                  // Add smaller image tiles, leaving space for the "+2" overlay if needed
                                  int overlayIndex = snapshot
                                              .data![index].imagePaths.length >
                                          4
                                      ? 4
                                      : snapshot.data![index].imagePaths.length;
                                  for (int i = 1; i < overlayIndex; i++) {
                                    tiles.add(
                                      StaggeredGridTile.count(
                                        crossAxisCellCount: 2,
                                        mainAxisCellCount: 2,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.file(
                                              File(snapshot
                                                  .data![index].imagePaths[i]),
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                    );
                                  }

                                  // Add the "+2" overlay tile if there are more than 4 images
                                  if (snapshot.data![index].imagePaths.length >
                                      4) {
                                    int additionalImages = snapshot
                                            .data![index].imagePaths.length -
                                        4;
                                    tiles.add(
                                      StaggeredGridTile.count(
                                        crossAxisCellCount: 2,
                                        mainAxisCellCount: 2,
                                        child: GestureDetector(
                                          onTap: Provider.of<JournalProvider>(
                                                  context)
                                              .pickImage,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Container(
                                              color:
                                                  Colors.black.withOpacity(0.5),
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
                                  final entry = snapshot.data![index];

                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                            child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) {
                                                  return JournalScreen(entry);
                                                },
                                              ),
                                            );
                                          },
                                          child: Card(
                                              margin: EdgeInsets.all(0),
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20.0,
                                                      vertical: 20),
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(entry.title,
                                                                style: TextStyle(
                                                                    height: 1,
                                                                    fontSize:
                                                                        30.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            SizedBox(height: 5),
                                                            Text(entry.content
                                                                .trim()),
                                                          ],
                                                        ),
                                                        SizedBox(height: 8),
                                                        snapshot.data![index]
                                                                    .imagePaths !=
                                                                []
                                                            ? StaggeredGrid
                                                                .count(
                                                                crossAxisCount:
                                                                    4,
                                                                mainAxisSpacing:
                                                                    4,
                                                                crossAxisSpacing:
                                                                    4,
                                                                children: tiles,
                                                              )
                                                            : SizedBox(),
                                                      ]))),
                                        ))),
                                  );
                                },
                              ),
                            );
                    }),
                SizedBox(
                  height: 120,
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 80, // Adjust the height to control the fade area
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
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 80, // Adjust the height to control the fade area
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 380, // Adjust the height to control the fade area
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
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width * 1,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Card(
                  margin: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedSize(
                                  // vsync: _animationController,

                                  duration: const Duration(milliseconds: 375),
                                  child: Container(
                                      padding: (result == "" && !isLoading)
                                          ? EdgeInsets.all(0)
                                          : EdgeInsets.all(12),
                                      child: (result == "" && !isLoading)
                                          ? Container()
                                          : isLoading
                                              ? Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: 8,
                                                    ),
                                                    Shimmer.fromColors(
                                                        child: Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.7,
                                                          height: 30,
                                                          decoration: BoxDecoration(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15)),
                                                        ),
                                                        highlightColor: Colors
                                                            .grey
                                                            .withOpacity(0.5),
                                                        baseColor: Theme.of(
                                                                context)
                                                            .backgroundColor),
                                                    SizedBox(
                                                      height: 20,
                                                    ),
                                                    Shimmer.fromColors(
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          height: 30,
                                                          decoration: BoxDecoration(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15)),
                                                        ),
                                                        highlightColor: Colors
                                                            .grey
                                                            .withOpacity(0.5),
                                                        baseColor: Theme.of(
                                                                context)
                                                            .backgroundColor),
                                                    SizedBox(
                                                      height: 20,
                                                    ),
                                                    Shimmer.fromColors(
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          height: 30,
                                                          decoration: BoxDecoration(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15)),
                                                        ),
                                                        highlightColor: Colors
                                                            .grey
                                                            .withOpacity(0.5),
                                                        baseColor: Theme.of(
                                                                context)
                                                            .backgroundColor)
                                                  ],
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Markdown(
                                                    data: result,
                                                    padding: EdgeInsets.all(0),
                                                    selectable: true,
                                                    onTapLink:
                                                        (text, href, title) {
                                                      launch(href!);
                                                    },
                                                    styleSheet:
                                                        MarkdownStyleSheet(),
                                                    physics:
                                                        NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                  ),
                                                )),
                                ));
                          }),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                          ),
                          Expanded(
                              child: TextField(
                            // controller: widget.controller,
                            minLines: 1,
                            maxLines: 2,
                            controller: _textEditingController,
                            cursorColor: Theme.of(context).colorScheme.primary,
                            textInputAction: TextInputAction.newline,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              hintText: 'Talk to your journal',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              isDense: true,
                            ),
                            onTapOutside: (event) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                          )),
                          GestureDetector(
                            onTap: result != ""
                                ? () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    _textEditingController.clear();
                                    setState(() {
                                      result = "";
                                    });
                                    _animationController.reverse();
                                  }
                                : () async {
                                    _animationController.forward();
                                    setState(() {
                                      isLoading = true;
                                    });
                                    result = await Provider.of<JournalProvider>(
                                            context,
                                            listen: false)
                                        .getResponseFromRAG(
                                            _textEditingController.text,
                                            widget.isTestUser
                                                ? ""
                                                : Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false)
                                                    .auth
                                                    .currentUser!
                                                    .uid);
                                    setState(() {
                                      isLoading = false;
                                    });
                                  },
                            child: Container(
                              margin: EdgeInsets.all(8),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withOpacity(0.3)),
                              child: Icon(
                                result != ""
                                    ? Icons.close_rounded
                                    : Icons.send_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

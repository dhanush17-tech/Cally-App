import 'dart:math';
import 'package:ai_calendar_app/providers/aiFunctions.dart';
import 'package:ai_calendar_app/providers/auth.dart' as auth;
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter_neat_and_clean_calendar/neat_and_clean_calendar_event.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import "package:intl/intl.dart";
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DateItem extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final Function(DateTime) onDateTap;
  final int eventCount;
  final int maxDotsToShow;

  DateItem({
    Key? key,
    required this.date,
    required this.isSelected,
    required this.onDateTap,
    this.eventCount = 0,
    this.maxDotsToShow = 4,
  }) : super(key: key);

  @override
  _DateItemState createState() => _DateItemState();
}

class _DateItemState extends State<DateItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // This is the important line

  @override
  Widget build(BuildContext context) {
    super.build(context); // You need to call this method

    // Generate dots for each event up to maxDotsToShow
    List<Widget> dots = List.generate(
      min(widget.eventCount, widget.maxDotsToShow),
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
    if (widget.eventCount > widget.maxDotsToShow) {
      dots.add(
        Text(
          '+${widget.eventCount - widget.maxDotsToShow} more',
          style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 10),
        ),
      );
    }

    return GestureDetector(
      onTap: () => widget.onDateTap(widget.date),
      child: Container(
        width: 70,
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE').format(widget.date), // Day of the week
              style: TextStyle(
                  color: widget.isSelected ? Colors.white : Colors.grey),
            ),
            Text(
              widget.date.day.toString(),
              style: TextStyle(
                color: widget.isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 5),
            Wrap(
              runSpacing: 5,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: dots.isEmpty ? [Container(width: 5, height: 5)] : dots,
            ),
          ],
        ),
      ),
    );
  }
// }

// class MyCachingWidget extends StatefulWidget {
//   final AIFunctions aiFunctions;
//   final bool isTestUser;
//   final String timezoneName;
//   MyCachingWidget(
//       {required this.aiFunctions,
//       this.isTestUser = false,
//       required this.timezoneName});

//   @override
//   _MyCachingWidgetState createState() => _MyCachingWidgetState();
// }

// class _MyCachingWidgetState extends State<MyCachingWidget>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive =>
//       false; // This tells Flutter to keep the widget alive

//   @override
//   Widget build(BuildContext context) {
//     super.build(context); // Need to call super.build
//     // Your widget build code
//     return Column(
//       children: [
//         EasyInfiniteDateTimeLine(
//           dayProps: EasyDayProps(
//             activeDayStyle: DayStyle(decoration: BoxDecoration()),
//             height: 110,
//           ),
//           controller: EasyInfiniteDateTimelineController(),
//           firstDate: DateTime.now(),
//           lastDate: DateTime(DateTime.now().year, DateTime.now().month + 3,
//               DateTime.now().day),
//           focusDate: widget.aiFunctions.selectedDate,
//           onDateChange: (selectedDate) async {
//             widget.aiFunctions.setSelectedDate(selectedDate);

//             widget.aiFunctions.getTodaysSummary(
//                 widget.isTestUser
//                     ? ""
//                     : Provider.of<auth.AuthProvider>(context, listen: false)
//                         .auth
//                         .currentUser!
//                         .uid,
//                 widget.timezoneName);
//             // Update your state to reflect the newly selected date
//           },
//           showTimelineHeader: false,
//           itemBuilder: (context, a, b, c, dateTime, isSelected) {
//             int maxDotsToShow = 4;
//             int eventsCount = widget.aiFunctions
//                 .eventsForSelectedDay(dateTime, widget.timezoneName)!
//                 .length;
//             List<Widget> dots = List<Widget>.generate(
//               min(eventsCount, maxDotsToShow),
//               (index) => Container(
//                 margin: EdgeInsets.only(right: 5),
//                 width: 5,
//                 height: 5,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//             );

//             // If there are more events than the maxDotsToShow, add a '+ more' indicator
//             if (eventsCount > maxDotsToShow) {
//               dots.add(Text('+${eventsCount - maxDotsToShow} more',
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyText2
//                       ?.copyWith(fontSize: 10)));
//             }

//             // Map<DateTime, int> dotsMap = {};

//             // // Loop through each event in the jsonEvents list
//             // for (var event in snap.data ?? {}) {
//             //   // Parse the event's start date as a DateTime object
//             //   DateTime eventDate =
//             //       DateTime.parse(event['startDate'])
//             //           .toLocal();

//             //   // If the date already exists in the map, increment its count, otherwise add it with a count of 1
//             //   if (dotsMap.containsKey(eventDate)) {
//             //     dotsMap[eventDate] =
//             //         dotsMap[eventDate]! + 1;
//             //   } else {
//             //     dotsMap[eventDate] = 1;
//             //   }
//             // }

//             return SingleChildScrollView(
//               child: Container(
//                 alignment: Alignment.center,
//                 padding: EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(10),
//                   color: widget.aiFunctions.selectedDate == dateTime
//                       ? Colors.blue.withOpacity(0.3)
//                       : Colors.grey.withOpacity(0.1),
//                 ),
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           DateFormat('EEE').format(dateTime), // Short day name.
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyText2
//                               ?.copyWith(
//                                 color: Theme.of(context).colorScheme.primary,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                         ),
//                         Text(
//                           dateTime.day.toString(),
//                           style: Theme.of(context).textTheme.headlineSmall,
//                         ),
//                         SizedBox(height: 5),
//                         Wrap(
//                           runSpacing: 5,
//                           alignment: WrapAlignment.center,
//                           runAlignment: WrapAlignment.center,
//                           children: dots.length == 0
//                               ? [
//                                   Container(
//                                       padding: EdgeInsets.only(right: 5),
//                                       width: 5,
//                                       height: 5,
//                                       decoration: BoxDecoration(
//                                         shape: BoxShape.circle,
//                                       ))
//                                 ]
//                               : dots,
//                         )
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );

//             // }
//             //      else {
//             //       // Show a placeholder or message if there are no events
//             //       return Shimmer.fromColors(
//             //         highlightColor: Colors.grey.withOpacity(0.5),
//             //         baseColor: Theme.of(context).backgroundColor,
//             //         child: Container(
//             //             alignment: Alignment.center,
//             //             padding: EdgeInsets.all(10),
//             //             decoration: BoxDecoration(
//             //               borderRadius: BorderRadius.circular(10),
//             //               color: Colors.grey.withOpacity(0.2),
//             //             )),}

//             // );
//           },
//         ),
//         Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 2.0),
//             child: Container(
//               child: ListView.builder(
//                 physics: NeverScrollableScrollPhysics(),
//                 shrinkWrap: true,
//                 padding: EdgeInsets.all(0),
//                 itemCount: widget.aiFunctions
//                     .eventsForSelectedDay(
//                         widget.aiFunctions.selectedDate, widget.timezoneName)
//                     .length,
//                 itemBuilder: (context, index) {
//                   final todoListProvider =
//                       Provider.of<AIFunctions>(context, listen: false);
//                   final list = widget.aiFunctions.eventsForSelectedDay(
//                       widget.aiFunctions.selectedDate, widget.timezoneName);
//                   var event = list[index];
//                   bool isCompleted =
//                       todoListProvider.eventIsDoneMap[event.metadata!['id']] ??
//                           false;
//                   return AnimationLimiter(
//                     child: AnimationConfiguration.staggeredList(
//                         position: index,
//                         child: SlideAnimation(
//                             verticalOffset: 50.0,
//                             child: FadeInAnimation(
//                               duration: Duration(milliseconds: 500),
//                               child: buildEventTile(
//                                   event, isCompleted, widget.aiFunctions),
//                             ))),
//                   );
//                 },
//               ),
//             )),
//       ],
//     );
//   }

//   Widget buildEventTile(
//       NeatCleanCalendarEvent event, bool isCompleted, AIFunctions aiFunctions) {
//     return GestureDetector(
//       onTap: () {
//         print(event.metadata!['meetingLink']);
//         if (event.metadata!['meetingLink'] != "") {
//           launchUrl(Uri.parse(event.metadata!['meetingLink']));
//         }
//         widget.aiFunctions.setEventIsDone(event.metadata!['id'], !isCompleted);
//       },
//       child: SizedBox(
//         height: 60,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               // Use Expanded to ensure the column takes up all available space on the left
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Flexible(
//                     // Wrap the title Text with Flexible
//                     child: Text(
//                       event.summary,
//                       style: Theme.of(context).textTheme.bodyText1?.copyWith(
//                             decoration:
//                                 isCompleted ? TextDecoration.lineThrough : null,
//                           ),
//                       softWrap: true, // Ensure text wraps
//                       overflow: TextOverflow
//                           .ellipsis, // Add an ellipsis if the text still overflows after wrapping
//                     ),
//                   ),
//                   Text(
//                     "${event.metadata!['startDate']} - ${event.metadata!['endDate']}",
//                     style: Theme.of(context).textTheme.bodyText2?.copyWith(
//                           decoration:
//                               isCompleted ? TextDecoration.lineThrough : null,
//                         ),
//                   ),
//                 ],
//               ),
//             ),
//             event.metadata!['meetingLink'] != ""
//                 ? Icon(Icons.videocam)
//                 : Container(
//                     width: 30,
//                     child: Checkbox(
//                       value: isCompleted,
//                       onChanged: (bool? newValue) {
//                         widget.aiFunctions
//                             .setEventIsDone(event.metadata!['id'], newValue!);
//                         // Force a rebuild or notify listeners to refresh the UI
//                       },
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }
}

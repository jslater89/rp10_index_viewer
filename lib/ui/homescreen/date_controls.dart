import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateControls extends StatefulWidget {
  final DateTime startingDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const DateControls({Key key, this.startingDate, this.onDateRangeChanged}) : super(key: key);

  @override
  _DateControlsState createState() => _DateControlsState();
}

class _DateControlsState extends State<DateControls> {
  DateTime startDate;
  DateTime endDate;
  DateFormat format = DateFormat.yMd();

  @override
  void initState() {
    super.initState();

    startDate = DateTime(widget.startingDate.year, widget.startingDate.month, widget.startingDate.day);
  }

  DateTime _parseDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _setStartDate(DateTime date) {
    var parsedDate = _parseDate(date);

    setState(() {
      startDate = parsedDate;
    });

    widget.onDateRangeChanged(startDate, endDate);
  }

  void _setEndDate(DateTime date) {
    var parsedDate = _parseDate(date);

    setState(() {
      endDate = parsedDate;
    });

    widget.onDateRangeChanged(startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    var startText = format.format(startDate);
    var endText = endDate != null ? format.format(endDate) : "(latest)";

    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FlatButton(
            child: Text("Start: $startText"),
            onPressed: () async {
              var date = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2020, 10, 27, 0),
                lastDate: DateTime.now().subtract(Duration(days: 1)),
              );

              if(date != null) {
                _setStartDate(date);
              }
            },
          ),
          SizedBox(width: 10),
          FlatButton(
            child: Text("End: $endText"),
            onPressed: () async {
              var date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020, 10, 28, 0),
                lastDate: DateTime.now(),
              );

              if(date != null) {
                _setEndDate(date);
              }
            },
          )
        ],
      )
    );
  }
}

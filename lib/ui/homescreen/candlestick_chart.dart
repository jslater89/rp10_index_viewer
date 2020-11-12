import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_candlesticks/flutter_candlesticks.dart';

class CandlestickChart extends StatelessWidget {
  const CandlestickChart({
    Key key,
    @required List<Map<String, double>> candlestickData,
  }) : _candlestickData = candlestickData, super(key: key);

  final List<Map<String, double>> _candlestickData;

  @override
  Widget build(BuildContext context) {
    var availableSize = MediaQuery.of(context).size;
    return Tooltip(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      message: "For this chart, the 'trading day' opens at 8 a.m. Eastern and closes with the last "
          "report of the day at 11 p.m.\nCandlesticks are green if today's close is higher than yesterday's close.\n"
          "Candlesticks are hollow if today's close is higher than today's open.",
      preferBelow: true,
      verticalOffset: 110,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _candlestickData != null ? min(availableSize.width, 25.0 * _candlestickData.length) : 0,
        ),
        child: OHLCVGraph(
          // increaseColor: Colors.red,
          // decreaseColor: Colors.green,
          previousDayMode: true,
          enableGridLines: true,
          gridLineAmount: 5,
          volumeProp: 0.0,
          data: _candlestickData,
        ),
      ),
    );
  }
}

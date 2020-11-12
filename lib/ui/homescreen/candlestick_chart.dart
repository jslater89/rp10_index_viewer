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
      message: "For this chart, the 'trading day' begins at 8 a.m. Eastern and ends with the last "
          "report of the day at 11 p.m.",
      preferBelow: true,
      verticalOffset: 110,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _candlestickData != null ? min(availableSize.width, 25.0 * _candlestickData.length) : 0,
        ),
        child: OHLCVGraph(
          // increaseColor: Colors.red,
          // decreaseColor: Colors.green,
          fillDecreasing: false,
          enableGridLines: true,
          gridLineAmount: 5,
          volumeProp: 0.0,
          data: _candlestickData,
        ),
      ),
    );
  }
}

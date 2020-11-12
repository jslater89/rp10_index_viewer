import 'package:flutter/material.dart';
import 'package:flutter_candlesticks/flutter_candlesticks.dart';

class CandlestickChart extends StatelessWidget {
  const CandlestickChart({
    Key key,
    @required this.secondRowHeight,
    @required List<Map<String, double>> candlestickData,
  }) : _candlestickData = candlestickData, super(key: key);

  final double secondRowHeight;
  final List<Map<String, double>> _candlestickData;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: secondRowHeight,
        width: _candlestickData != null ? 25 * _candlestickData.length : 0,
        child: Tooltip(
          message: "For this chart, the 'trading day' begins at 8 a.m. Eastern and ends with the last "
              "report of the day at 11 p.m.",
          preferBelow: true,
          verticalOffset: 110,
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
      ),
    );
  }
}

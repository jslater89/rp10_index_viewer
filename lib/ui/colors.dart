import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class ChartColors {
  static var blueGray = charts.Color.fromHex(code: Colors.blueGrey.htmlHex);
  static var red = charts.Color.fromHex(code: Colors.deepOrange.htmlHex);
}

extension ToHtmlHex on Color {
  String get htmlHex => '#${this.value.toRadixString(16).substring(2).padLeft(6, '0')}';
}
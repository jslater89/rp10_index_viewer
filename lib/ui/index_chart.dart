import 'dart:math';

/// Example of a combo time series chart with two series rendered as lines, and
/// a third rendered as points along the top line with a different color.
///
/// This example demonstrates a method for drawing points along a line using a
/// different color from the main series color. The line renderer supports
/// drawing points with the "includePoints" option, but those points will share
/// the same color as the line.
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rp10_index_server/index_quote.dart';
import 'package:charts_flutter/src/text_element.dart' as text;
import 'package:charts_flutter/src/text_style.dart' as style;

class IndexChart extends StatelessWidget {
  final List<charts.Series<IndexQuotePriceData, DateTime>> _seriesList;
  final bool animate;
  final DateTime first;
  final DateTime last;
  final double highPrice;
  final double lowPrice;

  factory IndexChart(List<IndexQuote> quotes) {
    double highPrice = 0, lowPrice = 1000;
    DateTime first = DateTime(3000), last = DateTime(0);

    for(var quote in quotes) {
      if(quote.indexPrice < lowPrice) lowPrice = quote.indexPrice;
      if(quote.indexPrice > highPrice) highPrice = quote.indexPrice;
      if(quote.time.isBefore(first)) first = quote.time;
      if(quote.time.isAfter(last)) last = quote.time;
    }

    var seriesList = [
      charts.Series<IndexQuotePriceData, DateTime>(
        data: quotes.map((it) => IndexQuotePriceData(it.time, it.indexPrice)).toList(),
        domainFn: (datum, _) => datum.time,
        measureFn: (datum, _) => datum.price,
        id: 'Index Quotes',
        colorFn: (datum, _) => charts.Color.fromHex(code: "#455A64"),
      )
    ];
    return IndexChart._internal(
      seriesList,
      animate: false,
      first: first,
      last: last,
      highPrice: highPrice,
      lowPrice: lowPrice,
    );
  }

  IndexChart._internal(this._seriesList, {this.animate, this.first, this.last, this.highPrice, this.lowPrice});

  List<charts.TickSpec<double>> _generatePriceTicks() {
    final topTick = _roundDouble(highPrice * 1.1, 2);
    var bottomTick = _roundDouble(lowPrice * 0.9, 2);
    if(bottomTick / topTick > 0.4) {
      bottomTick = 0.4 * topTick;
    }
    final difference = topTick - bottomTick;
    final middleTicks = 3;
    final tickInterval = difference / middleTicks.toDouble();

    var ticks = <charts.TickSpec<double>>[];
    ticks.add(charts.TickSpec(bottomTick, label: "\$${bottomTick.toStringAsFixed(2)}"));
    for(int i = 1; i <= middleTicks; i++) {
      final value = bottomTick + i*tickInterval;
      ticks.add(charts.TickSpec(value, label: "\$${value.toStringAsFixed(2)}"));
    }
    ticks.add(charts.TickSpec(topTick, label: "\$${topTick.toStringAsFixed(2)}"));

    return ticks;
  }

  DateTime _getExtentStart() {
    var difference = first.difference(last);
    var localFirst = first;
    if(difference.inDays < 1) {
      localFirst = last.subtract(Duration(days: 1));
    }
    else if(difference.inDays < 7) {
      localFirst = last.subtract(Duration(days: 7));
    }
    else if(difference.inDays < 30) {
      localFirst = last.subtract(Duration(days: 30));
    }
    return localFirst;
  }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      _seriesList,
      animate: animate,
      primaryMeasureAxis: charts.AxisSpec(
        tickProviderSpec: charts.StaticNumericTickProviderSpec(
          _generatePriceTicks()
        )
      ),
      domainAxis: charts.DateTimeAxisSpec(
        viewport: charts.DateTimeExtents(
          start: _getExtentStart(),
          end: last,
        )
      ),
      behaviors: [
        charts.SelectNearest(
          eventTrigger: charts.SelectionTrigger.hover,
          selectionModelType: SelectionModelType.info,
          maximumDomainDistancePx: 400,
          expandToDomain: true,
        ),
        LinePointHighlighter(
          selectionModelType: charts.SelectionModelType.info,
          symbolRenderer: CustomCircleSymbolRenderer()
        ),
      ],
      selectionModels: [
        SelectionModelConfig(
          type: SelectionModelType.info,
          changedListener: (SelectionModel model) {
            if(model.hasDatumSelection){
              final value = model.selectedDatum[0];
              CustomCircleSymbolRenderer.index = value.index;
              CustomCircleSymbolRenderer.indexTotal = model.selectedSeries[0].data.length;
              CustomCircleSymbolRenderer.value = value.datum;  // paints the tapped value
            }
          }
        )
      ],
    );
  }
}

class CustomCircleSymbolRenderer extends CircleSymbolRenderer {
  static IndexQuotePriceData value;
  static int index;
  static int indexTotal;
  @override
  void paint(ChartCanvas canvas, Rectangle<num> bounds, {List<int> dashPattern, Color fillColor, FillPatternType fillPattern, Color strokeColor, double strokeWidthPx}) {
    super.paint(canvas, bounds, dashPattern: dashPattern, fillColor: fillColor, strokeColor: strokeColor, strokeWidthPx: strokeWidthPx);

    DateTime utc = DateTime.fromMillisecondsSinceEpoch(value.time.millisecondsSinceEpoch, isUtc: true);
    DateTime local = utc.toLocal();

    var proportion = index.toDouble() / (indexTotal.toDouble() - 1);
    var leftOffset = -(proportion * 110) + 20;

    canvas.drawRect(
        Rectangle(bounds.left - 5, bounds.top - 30, bounds.width + 10, bounds.height + 10),
        fill: Color.transparent
    );
    var textStyle = style.TextStyle();
    textStyle.color = Color.black;
    textStyle.fontSize = 15;
    canvas.drawText(
        text.TextElement("\$${value.price.toStringAsFixed(3)}\n${DateFormat('M/d/yy HH:mm').format(local)}", style: textStyle),
        (bounds.left + leftOffset).round(),
        (bounds.top - 40).round()
    );
  }
}

/// Sample time series data type.
class IndexQuotePriceData {
  final DateTime time;
  final double price;

  IndexQuotePriceData(this.time, this.price);
}

double _roundDouble(double value, int places){
  double mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}

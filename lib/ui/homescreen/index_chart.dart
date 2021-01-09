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
import 'package:rp10_index_viewer/util/utils.dart';
import 'package:rp10_index_viewer/data/data_manager.dart';

class IndexChart extends StatelessWidget {
  final List<charts.Series<IndexQuote, DateTime>> _seriesList;
  final bool animate;
  final DateTime first;
  final DateTime last;
  final double highPrice;
  final double lowPrice;
  final bool touchMode;

  factory IndexChart(List<IndexQuote> quotes, {@required DateTime requestedStart, @required DateTime requestedEnd, bool touchMode = false}) {
    double highPrice = 0, lowPrice = 1000;
    DateTime first = DateTime(3000), last = DateTime(0);

    for(var quote in quotes) {
      if(quote.indexPrice != null && quote.indexPrice < lowPrice) lowPrice = quote.indexPrice;
      if(quote.indexPrice != null && quote.indexPrice > highPrice) highPrice = quote.indexPrice;
      if(quote.time.isBefore(first)) first = quote.time;
      if(quote.time.isAfter(last)) last = quote.time;
    }

    if(quotes.length > 2) {
      for (int i = 1; i < quotes.length; i++) {
        var lastQuote = quotes[i-1];
        var currentQuote = quotes[i];

        // Add a null quote so we get a gap
        var dataMode = DataInterval.forBounds(requestedStart, requestedEnd);
        var durationBeforeGap = Duration(hours: dataMode.hoursBetweenData(), minutes: 10);
        if(lastQuote.time.isBefore(currentQuote.time.subtract(durationBeforeGap))) {
          var dummyQuote = IndexQuote();
          dummyQuote.indexPrice = null;
          dummyQuote.time = lastQuote.time.add(Duration(minutes: 1));
          quotes.insert(i, dummyQuote);

          // Adding the quote means the old currentQuote is i+1, and we want
          // to be on the quote after currentQuote, so add 1 to i.
          i += 1;
        }
      }
    }

    var seriesList = [
      charts.Series<IndexQuote, DateTime>(
        data: quotes,
        domainFn: (datum, _) => datum.time,
        measureFn: (datum, _) => datum.indexPrice,
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
      touchMode: touchMode,
    );
  }

  IndexChart._internal(this._seriesList, {this.animate, this.first, this.last, this.highPrice, this.lowPrice, this.touchMode});

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

  @override
  Widget build(BuildContext context) {

    var selectBehavior;

    if(!touchMode) {
      selectBehavior = charts.SelectNearest(
        eventTrigger: charts.SelectionTrigger.hover,
        selectionModelType: SelectionModelType.info,
        maximumDomainDistancePx: 400,
        expandToDomain: true,
      );
    }
    else {
      selectBehavior = charts.SelectNearest(
        eventTrigger: charts.SelectionTrigger.tap,
        selectionModelType: SelectionModelType.info,
        maximumDomainDistancePx: 400,
        expandToDomain: true,
      );
    }

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
          start: Utilities.getExtentStart(first, last),
          end: last,
        )
      ),
      behaviors: [
        selectBehavior,
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
  static IndexQuote value;
  static int index;
  static int indexTotal;
  @override
  void paint(ChartCanvas canvas, Rectangle<num> bounds, {List<int> dashPattern, Color fillColor, FillPatternType fillPattern, Color strokeColor, double strokeWidthPx}) {
    super.paint(canvas, bounds, dashPattern: dashPattern, fillColor: fillColor, strokeColor: strokeColor, strokeWidthPx: strokeWidthPx);

    DateTime utc = DateTime.fromMillisecondsSinceEpoch(value.time.millisecondsSinceEpoch, isUtc: true);
    DateTime local = utc.toLocal();

    var proportion = index.toDouble() / (indexTotal.toDouble() - 1);
    var leftOffset = -(proportion * 110) + 10;

    canvas.drawRect(
        Rectangle(bounds.left - 5, bounds.top - 30, bounds.width + 10, bounds.height + 10),
        fill: Color.transparent
    );
    var textStyle = style.TextStyle();
    textStyle.color = Color.black;
    textStyle.fontSize = 15;
    canvas.drawText(
        text.TextElement("\$${value.indexPrice.toStringAsFixed(3)}\n${DateFormat('M/d/yy HH:mm').format(local)}", style: textStyle),
        (bounds.left + leftOffset).round(),
        (bounds.top - 40).round()
    );
  }
}

double _roundDouble(double value, int places){
  double mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}

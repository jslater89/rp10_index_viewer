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
import 'package:rp10_index_server/index_quote.dart';
import 'package:charts_flutter/src/text_element.dart' as text;
import 'package:charts_flutter/src/text_style.dart' as style;

class IndexChart extends StatelessWidget {
  final List<charts.Series<IndexQuotePriceData, DateTime>> _seriesList;
  final bool animate;

  IndexChart(List<IndexQuote> quotes, {this.animate = false}) : _seriesList = [
    charts.Series<IndexQuotePriceData, DateTime>(
      data: quotes.map((it) => IndexQuotePriceData(it.time, it.indexPrice)).toList(),
      domainFn: (datum, _) => datum.time,
      measureFn: (datum, _) => datum.price,
      id: 'Index Quotes',
    )
  ];

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      _seriesList,
      animate: animate,
      defaultRenderer: new charts.LineRendererConfig(),
      primaryMeasureAxis: charts.AxisSpec(
        tickProviderSpec: charts.StaticNumericTickProviderSpec(
          [
            charts.TickSpec(2.0, label: "\$2.00"),
            charts.TickSpec(4.0, label: "\$4.00"),
            charts.TickSpec(6.0, label: "\$6.00"),
            charts.TickSpec(8.0, label: "\$8.00"),
            charts.TickSpec(10.0, label: "\$10.00"),
          ]
        )
      ),
      behaviors: [
        LinePointHighlighter(
            symbolRenderer: CustomCircleSymbolRenderer()  // add this line in behaviours
        )
      ],
      selectionModels: [
        SelectionModelConfig(
            changedListener: (SelectionModel model) {
              if(model.hasDatumSelection){
                final value = model.selectedSeries[0].measureFn(model.selectedDatum[0].index);
                CustomCircleSymbolRenderer.value = value;  // paints the tapped value
              }
            }
        )
      ],
    );
  }
}

class CustomCircleSymbolRenderer extends CircleSymbolRenderer {
  static double value;
  @override
  void paint(ChartCanvas canvas, Rectangle<num> bounds, {List<int> dashPattern, Color fillColor, FillPatternType fillPattern, Color strokeColor, double strokeWidthPx}) {
    super.paint(canvas, bounds, dashPattern: dashPattern, fillColor: fillColor, strokeColor: strokeColor, strokeWidthPx: strokeWidthPx);
    canvas.drawRect(
        Rectangle(bounds.left - 5, bounds.top - 30, bounds.width + 10, bounds.height + 10),
        fill: Color.white
    );
    var textStyle = style.TextStyle();
    textStyle.color = Color.black;
    textStyle.fontSize = 15;
    canvas.drawText(
        text.TextElement("\$$value", style: textStyle),
        (bounds.left).round(),
        (bounds.top - 28).round()
    );
  }
}

/// Sample time series data type.
class IndexQuotePriceData {
  final DateTime time;
  final double price;

  IndexQuotePriceData(this.time, this.price);
}

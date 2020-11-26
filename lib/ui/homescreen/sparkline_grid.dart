import 'package:flutter/material.dart';
import 'package:rp10_index_server/ammo_price.dart';
import 'package:rp10_index_server/caliber.dart';
import 'package:rp10_index_viewer/ui/labeled_ammo_sparkline.dart';

class SparklineGrid extends StatelessWidget {
  const SparklineGrid({
    Key key,
    @required this.secondRowHeight,
    @required Map<String, List<AmmoPrice>> sparklinePrices,
  }) : _sparklinePrices = sparklinePrices, super(key: key);

  final double secondRowHeight;
  final Map<String, List<AmmoPrice>> _sparklinePrices;

  @override
  Widget build(BuildContext context) {
    double lowExtent = 1000;
    double highExtent = 0;

    for(var caliberPrices in _sparklinePrices?.values ?? []) {
      for(var price in caliberPrices) {
        if(price.price == null) continue;
        if(price.price < lowExtent) lowExtent = price.price;
        if(price.price > highExtent) highExtent = price.price;
      }
    }

    lowExtent -= 0.05;

    return Row(
      children: [
        Expanded(
            child: Container(
              height: secondRowHeight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(child: LabeledAmmoSparkline(label: "9mm", prices: _sparklinePrices[Caliber.nineMM.url], extentLow: lowExtent, extentHigh: highExtent)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".45", prices: _sparklinePrices[Caliber.fortyFive.url], extentLow: lowExtent, extentHigh: highExtent)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".40", prices: _sparklinePrices[Caliber.forty.url], extentLow: lowExtent, extentHigh: highExtent)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".38Spl", prices: _sparklinePrices[Caliber.thirtyEight.url], extentLow: lowExtent, extentHigh: highExtent)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".380", prices: _sparklinePrices[Caliber.threeEighty.url], extentLow: lowExtent, extentHigh: highExtent)),
                ],
              ),
            )
        ),
        Expanded(
            child: Container(
              height: secondRowHeight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(child: LabeledAmmoSparkline(label: "5.56", prices: _sparklinePrices[Caliber.fiveFiveSix.url], extentLow: lowExtent, extentHigh: highExtent)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".308", prices: _sparklinePrices[Caliber.threeOhEight.url], extentLow: lowExtent, extentHigh: highExtent)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".30-06", prices: _sparklinePrices[Caliber.thirtyOught.url], extentLow: lowExtent, extentHigh: highExtent)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: "x39", prices: _sparklinePrices[Caliber.sevenSixTwoRussianShort.url], extentLow: lowExtent, extentHigh: highExtent)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: "x54R", prices: _sparklinePrices[Caliber.sevenSixTwoRussianLong.url], extentLow: lowExtent, extentHigh: highExtent)),
                ],
              ),
            )
        ),
      ],
    );
  }
}
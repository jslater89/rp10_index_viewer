import 'package:flutter/material.dart';
import 'package:rp10_index_server/ammo_price.dart';
import 'package:rp10_index_server/caliber.dart';
import 'package:rp10_index_viewer/ui/labeled_ammo_sparkline.dart';

class SparklineGrid extends StatelessWidget {
  const SparklineGrid({
    Key key,
    @required this.secondRowHeight,
    @required Map<Caliber, List<AmmoPrice>> sparklinePrices,
  }) : _sparklinePrices = sparklinePrices, super(key: key);

  final double secondRowHeight;
  final Map<Caliber, List<AmmoPrice>> _sparklinePrices;

  @override
  Widget build(BuildContext context) {
    double pistolLow = 1000;
    double pistolHigh = 0;
    double rifleLow = 1000;
    double rifleHigh = 0;

    for(var caliberPrices in _sparklinePrices?.values ?? []) {
      for(AmmoPrice price in caliberPrices) {
        if (price.price == null) continue;
        if(price.caliber.isPistol) {
          if (price.price < pistolLow) pistolLow = price.price;
          if (price.price > pistolHigh) pistolHigh = price.price;
        }
        else {
          if (price.price < rifleLow) rifleLow = price.price;
          if (price.price > rifleHigh) rifleHigh = price.price;
        }
      }
    }

    pistolLow -= 0.05;
    rifleLow -= 0.05;

    return Row(
      children: [
        Expanded(
            child: Container(
              height: secondRowHeight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(child: LabeledAmmoSparkline(label: "9mm", prices: _sparklinePrices[Caliber.nineMM], extentLow: pistolLow, extentHigh: pistolHigh)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".45", prices: _sparklinePrices[Caliber.fortyFive], extentLow: pistolLow, extentHigh: pistolHigh)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".40", prices: _sparklinePrices[Caliber.forty], extentLow: pistolLow, extentHigh: pistolHigh)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".38Spl", prices: _sparklinePrices[Caliber.thirtyEight], extentLow: pistolLow, extentHigh: pistolHigh)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".380", prices: _sparklinePrices[Caliber.threeEighty], extentLow: pistolLow, extentHigh: pistolHigh)),
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
                  Expanded(child: LabeledAmmoSparkline(label: "5.56", prices: _sparklinePrices[Caliber.fiveFiveSix], extentLow: rifleLow, extentHigh: rifleHigh)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".308", prices: _sparklinePrices[Caliber.threeOhEight], extentLow: rifleLow, extentHigh: rifleHigh)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".30-06", prices: _sparklinePrices[Caliber.thirtyOught], extentLow: rifleLow, extentHigh: rifleHigh)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: "x39", prices: _sparklinePrices[Caliber.sevenSixTwoRussianShort], extentLow: rifleLow, extentHigh: rifleHigh)),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: "x54R", prices: _sparklinePrices[Caliber.sevenSixTwoRussianLong], extentLow: rifleLow, extentHigh: rifleHigh)),
                ],
              ),
            )
        ),
      ],
    );
  }
}
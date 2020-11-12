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
    return Row(
      children: [
        Expanded(
            child: Container(
              height: secondRowHeight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(child: LabeledAmmoSparkline(label: "9mm", prices: _sparklinePrices[Caliber.nineMM.url])),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".45", prices: _sparklinePrices[Caliber.fortyFive.url])),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".40", prices: _sparklinePrices[Caliber.forty.url])),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".38Spl", prices: _sparklinePrices[Caliber.thirtyEight.url])),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".380", prices: _sparklinePrices[Caliber.threeEighty.url])),
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
                  Expanded(child: LabeledAmmoSparkline(label: "5.56", prices: _sparklinePrices[Caliber.fiveFiveSix.url])),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".308", prices: _sparklinePrices[Caliber.threeOhEight.url])),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: ".30-06", prices: _sparklinePrices[Caliber.thirtyOught.url])),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: "x39", prices: _sparklinePrices[Caliber.sevenSixTwoRussianShort.url])),
                  SizedBox(height: 5),
                  Expanded(child: LabeledAmmoSparkline(label: "x54R", prices: _sparklinePrices[Caliber.sevenSixTwoRussianLong.url])),
                ],
              ),
            )
        ),
      ],
    );
  }
}
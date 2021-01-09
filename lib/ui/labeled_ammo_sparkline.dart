import 'package:flutter/material.dart';
import 'package:rp10_index_server/ammo_price.dart';
import 'package:rp10_index_viewer/ui/price_sparkline.dart';

class LabeledAmmoSparkline extends StatelessWidget {
  final String label;
  final List<AmmoPrice> prices;
  final double extentLow;
  final double extentHigh;
  final DateTime requestedStart;
  final DateTime requestedEnd;

  const LabeledAmmoSparkline({
    Key key, this.label, this.prices, this.extentLow, this.extentHigh, this.requestedStart, this.requestedEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 45, child: Align(alignment: Alignment.bottomRight, child: Text(label, softWrap: false, overflow: TextOverflow.fade,))),
        Expanded(flex: 15, child: PriceSparkline(prices, extentLow: extentLow, extentHigh: extentHigh, requestedStart: requestedStart, requestedEnd: requestedEnd)),
      ],
    );
  }
}
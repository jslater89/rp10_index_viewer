import 'package:flutter/material.dart';
import 'package:rp10_index_server/ammo_price.dart';
import 'package:rp10_index_viewer/ui/price_sparkline.dart';

class LabeledAmmoSparkline extends StatelessWidget {
  final String label;
  final List<AmmoPrice> prices;

  const LabeledAmmoSparkline({
    Key key, this.label, this.prices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 45, child: Align(alignment: Alignment.bottomRight, child: Text(label, softWrap: false, overflow: TextOverflow.fade,))),
        Expanded(flex: 15, child: PriceSparkline(prices)),
      ],
    );
  }
}
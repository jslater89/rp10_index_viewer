import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rp10_index_server/ammo_price.dart';
import 'package:rp10_index_server/caliber.dart';
import 'package:rp10_index_server/index_quote.dart';
import 'package:rp10_index_viewer/data/data_manager.dart';
import 'package:rp10_index_viewer/ui/homescreen/date_controls.dart';
import 'package:rp10_index_viewer/ui/homescreen/candlestick_chart.dart';
import 'package:rp10_index_viewer/ui/homescreen/sparkline_grid.dart';
import 'package:rp10_index_viewer/ui/homescreen/index_chart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'data/candlestick_day.dart';

void main() {
  tz.initializeTimeZones();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'R&P 10 Index',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'R&P 10 Index'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BuildContext _innerContext;
  List<IndexQuote> _quotes = [];
  List<Map<String, double>> _candlestickData;
  Map<Caliber, List<AmmoPrice>> _sparklinePrices = {};
  bool _touchMode = false;
  bool _sparklinesInitialized = false;
  bool _chartInitialized = false;

  @override
  void initState() {
    super.initState();

    for(var caliber in Caliber.values) {
      _sparklinePrices[caliber] = [];
    }

    _checkPlatform();
    _fetchIndexData(null, null);
    _fetchSparklineData(null, null);
  }

  Future<void> _checkPlatform() async {
    // if(browser.) {
    //   setState(() {
    //     _touchMode = true;
    //   });
    // }
  }

  Future<void> _fetchIndexData(DateTime start, DateTime end) async {
    if(start == null) start = DateTime.now().toUtc().subtract(Duration(days: 30));
    start = DateTime(start.year, start.month, start.day);
    if(end == null) end = DateTime.now().toUtc();

    var quotes = await DataManager().getQuotes(start, end);
    var candlestickData = await DataManager().getCandlestickDays(start, end);
    if(quotes != null) {
      _addChartData(quotes, candlestickData);
    }
    else {
      Scaffold.of(_innerContext).showSnackBar(SnackBar(content: Text("Error getting quote data!")));
    }
  }

  Future<void> _fetchSparklineData(DateTime start, DateTime end) async {
    if(start == null) start = DateTime.now().toUtc().subtract(Duration(days: 30));
    start = DateTime(start.year, start.month, start.day);
    if(end == null) end = DateTime.now();

    var prices = await DataManager().getPrices(start, end);
    Timer(Duration(milliseconds: _sparklinesInitialized ? 1250 : 2000), () => setState(() {
      _sparklinePrices = prices;
      _sparklinesInitialized = true;
    }));
  }

  void _addChartData(List<IndexQuote> quotes, List<CandlestickDay> candlestickData) {
    setState(() {
      _candlestickData = candlestickData.toDataFormat();
      _quotes = quotes;
    });

    Timer(Duration(milliseconds: _chartInitialized ? 1250 : 1250), () {
      setState((){
        _quotes = quotes;
      });
      _chartInitialized = true;
    });
  }

  void _updateData(DateTime start, DateTime end) async {
    _fetchIndexData(start, end);
    _fetchSparklineData(start, end);
  }

  @override
  Widget build(BuildContext context) {
    const firstRowHeight = 400.0;
    const secondRowHeight = 200.0;
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Builder(
        builder: (context) {
          _innerContext = context;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: firstRowHeight,
                      child: IndexChart(
                        _quotes,
                        touchMode: _touchMode,
                      ),
                    ),
                    SizedBox(height: 10),
                    DateControls(
                      startingDate: DateTime.now().toUtc().subtract(Duration(days: 30)),
                      onDateRangeChanged: _updateData,
                    )
                  ]..addAll([
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if(constraints.maxWidth < 960) {
                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: secondRowHeight,
                                alignment: Alignment.center,
                                child: _candlestickData != null ? CandlestickChart(candlestickData: _candlestickData) : Container(),
                              ),
                              SizedBox(height: 10),
                              SparklineGrid(secondRowHeight: secondRowHeight, sparklinePrices: _sparklinePrices),
                            ]
                          );
                        }
                        else {
                          return Container(
                            width: double.infinity,
                            height: secondRowHeight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  flex: 5,
                                  child: _candlestickData != null ? CandlestickChart(candlestickData: _candlestickData) : Container(),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: SparklineGrid(secondRowHeight: secondRowHeight, sparklinePrices: _sparklinePrices),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    )
                  ])..addAll([
                    SizedBox(height: 20),
                    Container(
                      width: 600,
                      child: Text("The Rifle & Pistol 10 is an index of ammunition prices. It is a weighted sum of 10 common "
                          "rifle and pistol calibers' costs per round. Ammoseek.com searches once per hour supply the data. 9mm "
                          "and 5.56 receive double weight. The other calibers receive no weighting. Handgun caliber searches are "
                          "conducted with the keyword 'FMJ'. Rifle caliber searches exclude the keyword 'tracer'.\n\n"
                          "If any caliber is entirely out of stock, it contributes to the index at 125% of its last recorded price (the Gunbroker Rule).\n\n"
                          "Calibers: 9mm, .45, .40, .38 Special, .380, 5.56, .308, .30-06, 7.62x39, 7.62x54R.\n\n"
                          "Contact @JayGSlater on Twitter if anything breaks.")
                    ),
                    SizedBox(height: 100),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
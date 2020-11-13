import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rp10_index_server/ammo_price.dart';
import 'package:rp10_index_server/caliber.dart';
import 'package:rp10_index_server/index_quote.dart';
import 'package:rp10_index_viewer/ui/homescreen/candlestick_chart.dart';
import 'package:rp10_index_viewer/ui/homescreen/sparkline_grid.dart';
import 'package:rp10_index_viewer/ui/homescreen/index_chart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  static const urlRoot = kDebugMode ? "http://localhost:8000" : "https://rp10.manywords.press";


  BuildContext _innerContext;
  List<IndexQuote> _quotes = [];
  List<Map<String, double>> _candlestickData;
  Map<String, List<AmmoPrice>> _sparklinePrices = {};
  bool _touchMode = false;

  @override
  void initState() {
    super.initState();

    for(var caliber in Caliber.values) {
      _sparklinePrices[caliber.url] = [];
    }

    _checkPlatform();
    _fetchIndexData();
    _fetchSparklineData();
  }

  Future<void> _checkPlatform() async {
    // if(browser.) {
    //   setState(() {
    //     _touchMode = true;
    //   });
    // }
  }

  Future<void> _fetchIndexData() async {
    var start = DateTime.now().toUtc().subtract(Duration(days: 30));
    start = DateTime(start.year, start.month, start.day);
    try {
      var response = await http.get("$urlRoot/quote?start=$start");

      if(response.statusCode == 200) {
        var quotes = IndexQuote.listFromJson(jsonDecode(response.body));
        _addChartData(quotes);
      }
      else {
        Scaffold.of(_innerContext).showSnackBar(SnackBar(content: Text("Response code: ${response.statusCode}")));
      }
    } catch(e) {
      Scaffold.of(_innerContext).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _fetchSparklineData() async {
    var start = DateTime.now().toUtc().subtract(Duration(days: 30));
    start = DateTime(start.year, start.month, start.day);
    try {
      var response = await http.get("$urlRoot/price?start=$start");

      if(response.statusCode == 200) {
        Map<String, dynamic> quotes = jsonDecode(response.body);
        Map<String, List<AmmoPrice>> prices = {};
        for(String caliberUrl in quotes.keys) {
          prices[caliberUrl] = AmmoPrice.listFromJson(quotes[caliberUrl]);
        }

        Timer(Duration(milliseconds: 1250), () => setState(() {
          _sparklinePrices = prices;
        }));
      }
    } catch(e) {
      Scaffold.of(_innerContext).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _addChartData(List<IndexQuote> quotes) {
    List<Map<String, double>> data = [];
    List<IndexQuote> dailyData = [];

    for(var quote in quotes) {
      if(dailyData.isEmpty) {
        dailyData.add(quote);
        continue;
      }

      // The 'exchange' is in EST
      var est = tz.getLocation("America/New_York");
      var lastExchangeTime = tz.TZDateTime.from(dailyData.last.time, est);
      var thisExchangeTime = tz.TZDateTime.from(quote.time, est);
      var endOfLastDay = tz.TZDateTime(est, lastExchangeTime.year, lastExchangeTime.month, lastExchangeTime.day, 23, 59, 59, 999);
      //
      // print("Daily data last: ${dailyData.last.time} ${dailyData.last.time.isUtc}");
      // print("Exchange time: $lastExchangeTime");
      // print("End of last day: $endOfLastDay");

      if(thisExchangeTime.isAfter(endOfLastDay)) {
        //print("Switching day: $thisExchangeTime is after $endOfLastDay");
        if(dailyData.isNotEmpty) data.add(_calculateCandlestickData(dailyData));
        dailyData = [quote];
      }
      else {
        dailyData.add(quote);
      }

      //print("Done\n");
    }

    if(dailyData.isNotEmpty) {
      data.add(_calculateCandlestickData(dailyData));
    }

    setState(() {
      _candlestickData = data;
      _quotes = quotes;
    });

    Timer(Duration(milliseconds: 1250), () => {
      setState((){
        _quotes = quotes;
      })
    });
  }

  Map<String, double> _calculateCandlestickData(List<IndexQuote> _dailyData) {
    double high = 0, low = 1000, open = 0, close = 0;
    for(var quote in _dailyData) {
      var est = tz.getLocation("America/New_York");
      var exchangeTime = tz.TZDateTime.from(quote.time, est);

      if(quote.indexPrice > high) high = quote.indexPrice;
      if(quote.indexPrice < low) low = quote.indexPrice;
      if(open == 0 && exchangeTime.hour >= 8) {
        open = quote.indexPrice;
      }
    }
    if(open == 0) open = _dailyData.first.indexPrice;
    close = _dailyData.last.indexPrice;

    return {
      "open": open,
      "close": close,
      "high": high,
      "low": low,
      "volumeto": 1,
    };
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
                          "and 5.56 receive double weight. The other calibers receive no weighting. All searches are conducted with "
                          "the keyword 'FMJ'.\n\n"
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
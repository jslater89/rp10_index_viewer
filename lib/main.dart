import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rp10_index_server/index_quote.dart';
import 'package:rp10_index_viewer/ui/index_chart.dart';
import 'package:timezone/data/latest.dart' as tz;

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

  @override
  void initState() {
    super.initState();

    _fetchData();
  }

  Future<void> _fetchData() async {
    var start = DateTime.now().toUtc().subtract(Duration(days: 30));
    start = DateTime(start.year, start.month, start.day);
    try {
      var urlRoot = kDebugMode ? "http://localhost:8000" : "https://rp10.manywords.press";
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

  void _addChartData(List<IndexQuote> quotes) {
    setState(() {
      _quotes = quotes;
    });

    Timer(Duration(milliseconds: 1000), () => {
      setState((){
        _quotes = quotes;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: SingleChildScrollView(
                child: Column(
                  // Column is also a layout widget. It takes a list of children and
                  // arranges them vertically. By default, it sizes itself to fit its
                  // children horizontally, and tries to be as tall as its parent.
                  //
                  // Invoke "debug painting" (press "p" in the console, choose the
                  // "Toggle Debug Paint" action from the Flutter Inspector in Android
                  // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
                  // to see the wireframe for each widget.
                  //
                  // Column has various properties to control how it sizes itself and
                  // how it positions its children. Here we use mainAxisAlignment to
                  // center the children vertically; the main axis here is the vertical
                  // axis because Columns are vertical (the cross axis would be
                  // horizontal).
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 400,
                      child: IndexChart(
                        _quotes
                      ),
                    ),
                    Container(
                      width: 600,
                      child: Text("The Rifle & Pistol 10 is an index of ammunition prices. It is a weighted sum of 10 common "
                          "rifle and pistol calibers' costs per round. Ammoseek.com searches once per hour supply the data. 9mm "
                          "and 5.56 receive double weight. The other calibers (.45, .40, .38 Special, .380, .308, .30-06, 7.62x39, "
                          "7.62x54R) receive no weighting.\n\n"
                          "If any caliber is entirely out of stock, \$10.00 is used as its cost per round. This will also "
                          "happen if Ammoseek changes the format of their results page.\n\n"
                          "If data doesn't appear, try resizing the window a bit. Flutter on the web is still not entirely mature.")
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

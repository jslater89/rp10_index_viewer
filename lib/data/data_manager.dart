import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rp10_index_server/ammo_price.dart';
import 'package:rp10_index_server/caliber.dart';
import 'package:rp10_index_server/index_quote.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'candlestick_day.dart';

/// DataManager fetches data from the server, caches it, and provides it to the
/// app.
class DataManager {
  //static const urlRoot = kDebugMode ? "https://cors-anywhere.herokuapp.com/https://rp10.manywords.press" : "https://rp10.manywords.press";
  static const urlRoot = kDebugMode ? "http://localhost:8000" : "https://rp10.manywords.press";

  DateTime firstRequested;
  DateTime lastRequested;
  List<IndexQuote> _quoteData = [];
  Map<Caliber, List<AmmoPrice>> _priceData = {};
  Future<void> _fetchLock;

  Future<List<CandlestickDay>> getCandlestickDays(DateTime start, DateTime end) async {
    var quotes = await getQuotes(start, end, reduceTemporalResolution: false);
    List<CandlestickDay> data = [];

    for(List<IndexQuote> dailyData in _splitByDays(quotes)) {
      if(dailyData.length > 0) data.add(_calculateCandlestickData(dailyData));
    }

    return data;
  }

  CandlestickDay _calculateCandlestickData(List<IndexQuote> _dailyData) {
    if(_dailyData.length == 0) throw ArgumentError();

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

    return CandlestickDay(
      open: open,
      close: close,
      high: high,
      low: low,
    );
  }

  Future<List<IndexQuote>> getQuotes(DateTime start, DateTime end, {bool reduceTemporalResolution = true}) async {
    if(_quoteData.length == 0 || firstRequested == null || lastRequested == null) {
      if(_fetchLock == null) _fetchLock = _fetchData(start, end);
      await _fetchLock;

      _fetchLock = null;
    }
    else if (firstRequested != null && lastRequested != null && (start.isBefore(firstRequested) || end.isAfter(lastRequested))){
      if(_fetchLock == null) _fetchLock = _fetchData(start, end);
      await _fetchLock;

      _fetchLock = null;
    }
    int startIndex = _quoteData.indexWhere((element) => element.time.isAfter(start)) ?? 0;
    int endIndex = (_quoteData.lastIndexWhere((element) => element.time.isBefore(end)) + 1) ?? _quoteData.length;
    var quotes = _quoteData.sublist(
      startIndex,
      endIndex
    );

    if(reduceTemporalResolution) {
      var dataMode = DataInterval.forBounds(start, end);
      if (dataMode == DataMode.dailyAverage) {
        print("Quote mode: daily average");
        var est = tz.getLocation("America/New_York");

        var averageQuotes = <IndexQuote>[];
        for (List<IndexQuote> daily in _splitByDays(quotes)) {
          if (daily.length == 0) continue;

          var noon = tz.TZDateTime(
              est, daily.first.time.year, daily.first.time.month,
              daily.first.time.day, 12);
          double price =
          daily.map((e) => e.indexPrice).reduce((value, element) =>
          value + element);

          IndexQuote quote = IndexQuote();
          quote.indexPrice = price / daily.length;
          quote.time = noon;
          averageQuotes.add(quote);
        }

        quotes = averageQuotes;
      }
      else if (dataMode == DataMode.everyFourth) {
        print("Quote mode: every 4th");
        int quoteIndex = 0;
        int totalQuotes = quotes.length;
        quotes.retainWhere((element) =>
        quoteIndex >= totalQuotes || quoteIndex++ % 4 == 0);
      }
      else if (dataMode == DataMode.everyOther) {
        print("Quote mode: every other");
        int quoteIndex = 0;
        int totalQuotes = quotes.length;
        quotes.retainWhere((element) =>
        quoteIndex >= totalQuotes || quoteIndex++ % 2 == 0);
      }
    }

    print("Quote count: ${quotes.length} out of ${_quoteData.length}, $startIndex to $endIndex");
    return quotes;
  }

  List<List<IndexQuote>> _splitByDays(List<IndexQuote> quotes) {
    List<List<IndexQuote>> dailyData = [];
    List<IndexQuote> thisDay = [];

    for(var quote in quotes) {
      if(thisDay.isEmpty) {
        thisDay.add(quote);
        continue;
      }

      // The 'exchange' is in EST
      var est = tz.getLocation("America/New_York");
      var lastExchangeTime = tz.TZDateTime.from(thisDay.last.time, est);
      var thisExchangeTime = tz.TZDateTime.from(quote.time, est);
      var endOfLastDay = tz.TZDateTime(est, lastExchangeTime.year, lastExchangeTime.month, lastExchangeTime.day, 23, 59, 59, 999);
      //
      // print("Daily data last: ${dailyData.last.time} ${dailyData.last.time.isUtc}");
      // print("Exchange time: $lastExchangeTime");
      // print("End of last day: $endOfLastDay");

      if(thisExchangeTime.isAfter(endOfLastDay)) {
        //print("Switching day: $thisExchangeTime is after $endOfLastDay");
        if(thisDay.isNotEmpty) dailyData.add([]..addAll(thisDay));
        thisDay = [quote];
      }
      else {
        thisDay.add(quote);
      }

      //print("Done\n");
    }

    if(thisDay.isNotEmpty) {
      dailyData.add([]..addAll(thisDay));
    }

    return dailyData;
  }

  List<List<AmmoPrice>> _splitPricesByDays(List<AmmoPrice> prices) {
    List<List<AmmoPrice>> dailyData = [];
    List<AmmoPrice> thisDay = [];

    for(var price in prices) {
      if(thisDay.isEmpty) {
        thisDay.add(price);
        continue;
      }

      // The 'exchange' is in EST
      var est = tz.getLocation("America/New_York");
      var lastExchangeTime = tz.TZDateTime.from(thisDay.last.time, est);
      var thisExchangeTime = tz.TZDateTime.from(price.time, est);
      var endOfLastDay = tz.TZDateTime(est, lastExchangeTime.year, lastExchangeTime.month, lastExchangeTime.day, 23, 59, 59, 999);
      //
      // print("Daily data last: ${dailyData.last.time} ${dailyData.last.time.isUtc}");
      // print("Exchange time: $lastExchangeTime");
      // print("End of last day: $endOfLastDay");

      if(thisExchangeTime.isAfter(endOfLastDay)) {
        //print("Switching day: $thisExchangeTime is after $endOfLastDay");
        if(thisDay.isNotEmpty) dailyData.add([]..addAll(thisDay));
        thisDay = [price];
      }
      else {
        thisDay.add(price);
      }

      //print("Done\n");
    }

    if(thisDay.isNotEmpty) {
      dailyData.add([]..addAll(thisDay));
    }

    return dailyData;
  }

  Future<Map<Caliber, List<AmmoPrice>>> getPrices(DateTime start, DateTime end, {bool reduceTemporalResolution = true}) async {
    if(_priceData.length == 0 || firstRequested == null || lastRequested == null) {
      if(_fetchLock == null) _fetchLock = _fetchData(start, end);
      await _fetchLock;

      _fetchLock = null;
    }
    else if (firstRequested != null && lastRequested != null && (start.isBefore(firstRequested) || end.isAfter(lastRequested))){
      if(_fetchLock == null) _fetchLock = _fetchData(start, end);
      await _fetchLock;

      _fetchLock = null;
    }
    Map<Caliber, List<AmmoPrice>> filteredData = {};
    int startI = -1;
    int endI = -1;
    for(var c in Caliber.values) {
      int startIndex = _priceData[c].indexWhere((element) => element.time.isAfter(start)) ?? 0;
      int endIndex = (_priceData[c].lastIndexWhere((element) => element.time.isBefore(end)) + 1) ?? _quoteData.length;
      if(startI == -1) {
        startI = startIndex;
        endI = endIndex;
      }

      filteredData[c] = _priceData[c].sublist(startIndex, endIndex);

      if(reduceTemporalResolution) {
        var dataMode = DataInterval.forBounds(start, end);
        if (dataMode == DataMode.dailyAverage) {
          var est = tz.getLocation("America/New_York");

          var averagePrices = <AmmoPrice>[];
          for (List<AmmoPrice> daily in _splitPricesByDays(filteredData[c])) {
            if (daily.length == 0) continue;

            var noon = tz.TZDateTime(
                est, daily.first.time.year, daily.first.time.month,
                daily.first.time.day, 12);
            double price =
            daily.map((e) => e.price).reduce((value, element) =>
            value + element);

            AmmoPrice quote = AmmoPrice();
            quote.price = price / daily.length;
            quote.caliber = daily.first.caliber;
            quote.inStock = daily.map((e) => e.inStock).reduce((value, element) => value && element);
            quote.time = noon;
            
            averagePrices.add(quote);
          }

          filteredData[c] = averagePrices;
        }
        else if (dataMode == DataMode.everyFourth) {
          int quoteIndex = 0;
          int totalQuotes = filteredData[c].length;
          filteredData[c].retainWhere((element) =>
            quoteIndex >= totalQuotes || quoteIndex++ % 4 == 0);
        }
        else if (dataMode == DataMode.everyOther) {
          int quoteIndex = 0;
          int totalQuotes = filteredData[c].length;
          filteredData[c].retainWhere((element) =>
            quoteIndex >= totalQuotes || quoteIndex++ % 2 == 0);
        }
      }
    }
    print("Price count: ${filteredData[Caliber.nineMM].length} out of ${_priceData[Caliber.nineMM].length}, $startI to $endI");
    return filteredData;
  }

  /// Get quotes and caliber prices for the given range as needed to fill in what the data manager
  /// doesn't already have
  Future<void> _fetchData(DateTime start, DateTime end) async {
    if(firstRequested == null || lastRequested == null) {
      print("Getting initial data between $start and $end");
      // Initial pull
      _quoteData = await _fetchQuotes(start, end);
      _priceData = await _fetchPrices(start, end);
      firstRequested = start;
      lastRequested = end;
    }
    else {
      print("Checking if fetch needed from $start to $end");
      DateTime preRangeStart = start;
      DateTime preRangeEnd = firstRequested.subtract(Duration(minutes: 1));
      if(preRangeStart.isBefore(preRangeEnd)) {
        print("Moving start back to $preRangeStart");
        var quotes = await _fetchQuotes(preRangeStart, preRangeEnd);
        var prices = await _fetchPrices(preRangeStart, preRangeEnd);

        if(quotes != null && prices != null) {
          print("Fetched ${quotes.length} new quotes, ${prices[Caliber.nineMM].length} new prices");
          _quoteData = quotes..addAll(_quoteData);
          for(Caliber c in Caliber.values) {
            _priceData[c] = prices[c]..addAll(_priceData[c]);
          }

          firstRequested = preRangeStart;
        }
        else {
          print("Got a null quotes or prices");
        }
      }

      DateTime postRangeStart = lastRequested.add(Duration(minutes: 1));
      DateTime postRangeEnd = end;
      if(postRangeEnd.isAfter(postRangeStart)) {
        print("Moving end forward to $postRangeEnd");
        var quotes = await _fetchQuotes(postRangeEnd, postRangeEnd);
        var prices = await _fetchPrices(postRangeStart, postRangeEnd);

        if(quotes != null && prices != null) {
          print("Fetched ${quotes.length} new quotes, ${prices[Caliber.nineMM].length} new prices");
          _quoteData = _quoteData..addAll(quotes);
          for(Caliber c in Caliber.values) {
            _priceData[c] = _priceData[c]..addAll(prices[c]);
          }

          lastRequested = postRangeEnd;
        }
        else {
          print("Got a null quotes or prices");
        }
      }
    }
  }

  Future<List<IndexQuote>> _fetchQuotes(DateTime start, DateTime end) async {
    try {
      var url = "$urlRoot/quote?start=$start";
      if(end != null) url = "$urlRoot/quote?start=$start&end=$end";
      var response = await http.get(url);

      if(response.statusCode == 200) {
        var quotes = IndexQuote.listFromJson(jsonDecode(response.body));
        return quotes;
      }
      else {
        print("Response code: ${response.statusCode} ${response.body}");
      }
    } catch(e) {
      print("Error: $e");
    }
    return null;
  }

  Future<Map<Caliber, List<AmmoPrice>>> _fetchPrices(DateTime start, DateTime end) async {
    try {
      var url = "$urlRoot/price?start=$start";
      if(end != null) url = "$urlRoot/price?start=$start&end=$end";
      var response = await http.get(url);

      if(response.statusCode == 200) {
        Map<String, dynamic> quotes = jsonDecode(response.body);
        Map<Caliber, List<AmmoPrice>> prices = {};
        for(String caliberUrl in quotes.keys) {
          prices[CaliberUtils.fromUrl(caliberUrl)] = AmmoPrice.listFromJson(quotes[caliberUrl]);
        }
        return prices;
      }
    } catch(e) {
      print("Error: $e");
    }
    return null;
  }

  // ---- Singleton setup
  static DataManager _instance;

  factory DataManager() {
    if(_instance == null) {
      _instance = DataManager._internal();
    }

    return _instance;
  }

  DataManager._internal();
}

enum DataMode {
  all,
  everyOther,
  everyFourth,
  dailyAverage,
}

extension DataInterval on DataMode {
  static DataMode forBounds(DateTime start, DateTime end) {
    var duration = end.difference(start);
    if(duration.inDays >= 120) {
      return DataMode.dailyAverage;
    }
    else if(duration.inDays >= 90) {
      return DataMode.everyFourth;
    }
    else if(duration.inDays >= 60) {
      return DataMode.everyOther;
    }
    else  {
      return DataMode.all;
    }
  }

  int hoursBetweenData() {
    switch(this) {
      case DataMode.all:
        return 1;
        break;
      case DataMode.everyOther:
        return 2;
        break;
      case DataMode.everyFourth:
        return 4;
        break;
      case DataMode.dailyAverage:
        return 24;
        break;
    }
  }
}
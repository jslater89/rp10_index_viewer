import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rp10_index_server/ammo_price.dart';
import 'package:rp10_index_server/caliber.dart';
import 'package:rp10_index_server/index_quote.dart';
import 'package:http/http.dart' as http;

/// DataManager fetches data from the server, caches it, and provides it to the
/// app.
class DataManager {
  static const urlRoot = kDebugMode ? "http://localhost:8000" : "https://rp10.manywords.press";

  DateTime firstRequested;
  DateTime lastRequested;
  List<IndexQuote> _quoteData = [];
  Map<Caliber, List<AmmoPrice>> _priceData = {};
  Future<void> _fetchLock;

  Future<List<IndexQuote>> getQuotes(DateTime start, DateTime end) async {
    if(_quoteData.length == 0 || firstRequested == null || lastRequested == null) {
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

    print("Quote count: ${quotes.length} out of ${_quoteData.length}, $startIndex to $endIndex");
    return quotes;
  }

  Future<Map<Caliber, List<AmmoPrice>>> getPrices(DateTime start, DateTime end) async {
    if(_priceData.length == 0 || firstRequested == null || lastRequested == null) {
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
      DateTime preRangeStart = start;
      DateTime preRangeEnd = firstRequested.subtract(Duration(minutes: 1));
      if(preRangeStart.isBefore(preRangeEnd)) {
        // TODO: fetch before data, add new quotes
        firstRequested = start;
      }

      DateTime postRangeStart = lastRequested.add(Duration(minutes: 1));
      DateTime postRangeEnd = end;
      if(postRangeEnd.isAfter(postRangeStart)) {
        // TODO: fetch, add, etc.
        lastRequested = end;
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
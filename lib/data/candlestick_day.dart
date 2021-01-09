/// CandlestickDay holds data required for a candlestick chart in user-friendly
/// fashion, and provides a convenience method for converting it to the less
/// friendly format expected by the candlestick lib.
class CandlestickDay {
  final double open;
  final double close;
  final double high;
  final double low;

  CandlestickDay({this.open, this.close, this.high, this.low});

  Map<String, double> toDataFormat() {
    return {
      "open": open,
      "close": close,
      "high": high,
      "low": low,
      "volumeto": 1.0,
    };
  }
}

extension ToDataFormat on List<CandlestickDay> {
  List<Map<String, double>> toDataFormat() {
    return map((e) => e.toDataFormat()).toList();
  }
}
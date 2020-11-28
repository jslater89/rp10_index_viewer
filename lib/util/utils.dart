class Utilities {
  static DateTime getExtentStart(DateTime first, DateTime last) {
    // var difference = last.difference(first);
    var localFirst = first;
    // if(difference.inDays < 1) {
    //   localFirst = last.subtract(Duration(days: 1));
    // }
    // else if(difference.inDays < 3) {
    //   localFirst = last.subtract(Duration(days: 3));
    // }
    // else if(difference.inDays < 7) {
    //   localFirst = last.subtract(Duration(days: 7));
    // }
    // else if(difference.inDays < 14) {
    //   localFirst = last.subtract(Duration(days: 14));
    // }
    // else if(difference.inDays < 30) {
    //   localFirst = last.subtract(Duration(days: 30));
    // }
    return localFirst;
  }
}
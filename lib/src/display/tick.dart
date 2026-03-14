import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

/// Because not all ticks will have a label there is a difference between the 
/// code that determines the tick location and the code for tick labels.   
/// Determining labels is a separate process which is more complex because it 
/// involves formatting, localization, and other considerations like rotation 
/// and the overall size of the chart.  Tick locations should not change as 
/// the chart is resized, but the tick labels may change. 

class Tick {
  Tick(this.dateTime, this.label);

  final TZDateTime dateTime;
  final String label;

}


/// Auto ticks for date time axis.
/// 
/// 
List<TZDateTime> autoTicks(({TZDateTime start, TZDateTime end}) domain) {
  var term = Term(Date.containing(domain.start), Date.containing(domain.end));
  final dayCount = term.dayCount();
  final idx = switch (dayCount) {
    0 || 1 => 1,
    _ => _leftEqFirstSearch(dayCount)
  };

  switch (idx) {
    case 0: // less than one day
      return [domain.start, domain.end];
    case 1: // one day
      return [
        domain.start,
        Date.containing(domain.start).next.start,
        domain.end,
      ];
    case 2: // 
      return [
        domain.start,
        Date.containing(domain.start).next.start,
        Date.containing(domain.start).next.next.start,
        domain.end,
      ];
    case 3: // between 4 and 8 days
      var ticks = <TZDateTime>[];
      var tick = Date.containing(domain.start).next.start;
      while (tick.isBefore(domain.end)) {
        ticks.add(tick);
        tick = tick.add(const Duration(days: 1));
      }
      return ticks;
    default:
      return [];
  }
}

/// Different behavior depending on the domain of the ticks.
///
const List<int> dayBreaks = [
  0,
  1,
  2,
  4,
  8,
  15,
  31,
  92,
  366,
  3660,
  36600,
  366000,
];

/// Find the index of the element in the [dayBreaks] list where the
/// element is <= value.
int _leftEqFirstSearch(int value) {
  var min = 0;
  var max = dayBreaks.length - 1;
  while (min < max) {
    var mid = min + ((max - min) >> 1);
    var element = dayBreaks[mid];
    var comp = element.compareTo(value);
    if (comp == 0) return mid;
    if (element < value) {
      if (mid + 1 == dayBreaks.length) return mid;
      if (dayBreaks[mid + 1] > value) return mid;
    }
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return -1;
}

TZDateTime dateTick0() {
  return TZDateTime.now(local);
}

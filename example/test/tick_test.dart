// import 'package:timezone/data/latest.dart';
// import 'package:timezone/timezone.dart';
// import 'package:flutter_test/flutter_test.dart';

// void tests() {
//   group('auto ticks', () {
//     test('5 days', () {
//       var start = TZDateTime(local, 2020, 1, 1);
//       var end = TZDateTime(local, 2020, 1, 6);
//       var ticks = autoTicks((start: start, end: end));
//       expect(ticks.length, 4);
//       expect(ticks[0], TZDateTime(local, 2020, 1, 2));
//       expect(ticks[1], TZDateTime(local, 2020, 1, 3));
//       expect(ticks[2], TZDateTime(local, 2020, 1, 4));
//       expect(ticks[3], TZDateTime(local, 2020, 1, 5));
//     });
//   });
// }

// void main() {
//   initializeTimeZones();
//   tests();
// }

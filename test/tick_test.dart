import 'package:flutter_test/flutter_test.dart';
import 'package:graphic_lite/graphic_lite.dart';
import 'package:timezone/data/latest_10y.dart';
import 'package:timezone/timezone.dart';

void tests() {
  group('auto tick position', () {
    final tz = getLocation('America/New_York');
    test('one day market hours', () {
      final ticks = autoTicks((
        start: TZDateTime.parse(tz, '2024-01-01 09:30:00'),
        end: TZDateTime.parse(tz, '2024-01-01 16:00:00'),
      ));
      print(ticks);
      expect(ticks.length, 2);
    });
  });
}

void main() {
  initializeTimeZones();
  tests();
}

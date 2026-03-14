import 'package:core/core.dart';
import 'package:qibla/qibla.dart';
import 'package:test/test.dart';

void main() {
  group('QiblaCalculator', () {
    const QiblaCalculator calculator = QiblaCalculator();

    test('calculates expected bearing from Chicago', () {
      final QiblaDirection result = calculator.calculate(
        const Coordinates(latitude: 41.8781, longitude: -87.6298),
      );

      expect(result.bearingFromTrueNorth, closeTo(48.67, 0.01));
    });

    test('calculates expected bearing from London', () {
      final QiblaDirection result = calculator.calculate(
        const Coordinates(latitude: 51.5074, longitude: -0.1278),
      );

      expect(result.bearingFromTrueNorth, closeTo(118.99, 0.01));
    });

    test('calculates expected bearing from Kuala Lumpur', () {
      final QiblaDirection result = calculator.calculate(
        const Coordinates(latitude: 3.1390, longitude: 101.6869),
      );

      expect(result.bearingFromTrueNorth, closeTo(292.54, 0.01));
    });
  });
}

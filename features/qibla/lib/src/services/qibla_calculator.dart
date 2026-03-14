import 'dart:math' as math;

import 'package:core/core.dart';

import '../domain/qibla_direction.dart';

class QiblaCalculator {
  const QiblaCalculator();

  static const Coordinates kaabaCoordinates = Coordinates(
    latitude: 21.422487,
    longitude: 39.826206,
  );

  QiblaDirection calculate(Coordinates from) {
    final double latitude = _toRadians(from.latitude);
    final double kaabaLatitude = _toRadians(kaabaCoordinates.latitude);
    final double deltaLongitude =
        _toRadians(kaabaCoordinates.longitude - from.longitude);

    final double x = math.sin(deltaLongitude);
    final double y = math.cos(latitude) * math.tan(kaabaLatitude) -
        math.sin(latitude) * math.cos(deltaLongitude);
    final double bearing = (_toDegrees(math.atan2(x, y)) + 360.0) % 360.0;

    return QiblaDirection(bearingFromTrueNorth: bearing);
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;

  double _toDegrees(double radians) => radians * 180.0 / math.pi;
}

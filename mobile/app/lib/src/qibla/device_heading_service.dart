import 'package:flutter_compass/flutter_compass.dart';

class DeviceHeading {
  const DeviceHeading({
    required this.degreesFromNorth,
  });

  final double degreesFromNorth;
}

abstract interface class DeviceHeadingService {
  Stream<DeviceHeading?> headingStream();
}

class FlutterCompassHeadingService implements DeviceHeadingService {
  const FlutterCompassHeadingService();

  @override
  Stream<DeviceHeading?> headingStream() {
    final Stream<CompassEvent>? events = FlutterCompass.events;
    if (events == null) {
      return const Stream<DeviceHeading?>.empty();
    }

    return events.map((CompassEvent event) {
      final double? heading = event.heading;
      if (heading == null || heading.isNaN) {
        return null;
      }
      return DeviceHeading(
        degreesFromNorth: (heading + 360.0) % 360.0,
      );
    });
  }
}

import 'package:core/core.dart';
import 'package:geolocator/geolocator.dart';

enum DeviceLocationStatus {
  ready,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class DeviceLocationResult {
  const DeviceLocationResult({
    required this.status,
    required this.message,
    this.coordinates,
  });

  final DeviceLocationStatus status;
  final String message;
  final Coordinates? coordinates;
}

abstract interface class DeviceLocationService {
  Future<DeviceLocationResult> resolve({
    required bool requestPermission,
  });
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  const GeolocatorDeviceLocationService();

  @override
  Future<DeviceLocationResult> resolve({
    required bool requestPermission,
  }) async {
    final bool servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      return const DeviceLocationResult(
        status: DeviceLocationStatus.servicesDisabled,
        message:
            'Device location is turned off, so the app is using your manual coordinates instead.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const DeviceLocationResult(
        status: DeviceLocationStatus.permissionDenied,
        message:
            'Location permission was not granted, so the app is using your manual coordinates instead.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const DeviceLocationResult(
        status: DeviceLocationStatus.permissionDeniedForever,
        message:
            'Location permission is permanently denied. Open system settings to re-enable it or keep using manual coordinates.',
      );
    }

    Position? position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return DeviceLocationResult(
      status: DeviceLocationStatus.ready,
      message: 'Using your device location for prayer times and qibla.',
      coordinates: Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }
}

class FakeDeviceLocationService implements DeviceLocationService {
  const FakeDeviceLocationService(this.result);

  final DeviceLocationResult result;

  @override
  Future<DeviceLocationResult> resolve({
    required bool requestPermission,
  }) async {
    return result;
  }
}

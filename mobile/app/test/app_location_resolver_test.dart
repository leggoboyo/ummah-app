import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_location_resolver.dart';
import 'package:ummah_mobile_app/src/bootstrap/app_profile.dart';
import 'package:ummah_mobile_app/src/bootstrap/device_location_service.dart';

void main() {
  test('manual mode does not consult device location service', () async {
    final _CountingLocationService service = _CountingLocationService();
    final AppLocationResolver resolver = AppLocationResolver(
      locationService: service,
      describeTimeZone: (_, __) => 'UTC-05:00',
    );
    final AppProfile profile = AppProfile.defaults();

    final result = await resolver.resolve(
      profile: profile,
      requestPermission: true,
    );

    expect(service.resolveCalls, 0);
    expect(result.coordinates, profile.manualCoordinates);
    expect(result.summary, contains(profile.manualLocationLabel));
  });

  test('device mode falls back to manual coordinates when gps is unavailable',
      () async {
    const Coordinates fallback =
        Coordinates(latitude: 41.8781, longitude: -87.6298);
    final AppProfile profile = AppProfile.defaults().copyWith(
      locationMode: AppLocationMode.device,
      manualCoordinates: fallback,
    );
    final AppLocationResolver resolver = AppLocationResolver(
      locationService: const FakeDeviceLocationService(
        DeviceLocationResult(
          status: DeviceLocationStatus.permissionDenied,
          message: 'Permission denied.',
        ),
      ),
      describeTimeZone: (_, __) => 'UTC-05:00',
    );

    final result = await resolver.resolve(
      profile: profile,
      requestPermission: false,
    );

    expect(result.coordinates, fallback);
    expect(result.bannerMessage, 'Permission denied.');
  });
}

class _CountingLocationService implements DeviceLocationService {
  int resolveCalls = 0;

  @override
  Future<DeviceLocationResult> resolve({
    required bool requestPermission,
  }) async {
    resolveCalls += 1;
    return const DeviceLocationResult(
      status: DeviceLocationStatus.unavailable,
      message: 'Should not be called.',
    );
  }
}

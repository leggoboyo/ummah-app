import 'app_location_state.dart';
import 'app_profile.dart';
import 'device_location_service.dart';

typedef TimeZoneDescriptionFormatter = String Function(String, DateTime);

class AppLocationResolver {
  const AppLocationResolver({
    required DeviceLocationService locationService,
    required TimeZoneDescriptionFormatter describeTimeZone,
  })  : _locationService = locationService,
        _describeTimeZone = describeTimeZone;

  final DeviceLocationService _locationService;
  final TimeZoneDescriptionFormatter _describeTimeZone;

  Future<AppLocationState> resolve({
    required AppProfile profile,
    required bool requestPermission,
  }) async {
    if (profile.locationMode == AppLocationMode.manual) {
      return manual(profile);
    }

    final DeviceLocationResult result = await _locationService.resolve(
      requestPermission: requestPermission,
    );
    if (result.coordinates != null) {
      return AppLocationState(
        coordinates: result.coordinates!,
        summary: result.message,
      );
    }

    return AppLocationState(
      coordinates: profile.manualCoordinates,
      summary: result.message,
      bannerMessage: result.message,
    );
  }

  AppLocationState manual(AppProfile profile) {
    return AppLocationState(
      coordinates: profile.manualCoordinates,
      summary:
          'Using ${profile.manualLocationLabel} (${_describeTimeZone(profile.manualTimeZoneId, DateTime.now())}) for manual prayer times.',
    );
  }
}

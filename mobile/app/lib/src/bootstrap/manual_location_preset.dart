import 'dart:math' as math;

import 'package:core/core.dart';

class ManualLocationPreset {
  const ManualLocationPreset({
    required this.id,
    required this.city,
    required this.country,
    required this.coordinates,
    required this.timeZoneId,
  });

  final String id;
  final String city;
  final String country;
  final Coordinates coordinates;
  final String timeZoneId;

  String get label => '$city, $country';
}

const List<ManualLocationPreset> kManualLocationPresets =
    <ManualLocationPreset>[
  ManualLocationPreset(
    id: 'chicago_us',
    city: 'Chicago',
    country: 'United States',
    coordinates: Coordinates(latitude: 41.8781, longitude: -87.6298),
    timeZoneId: 'America/Chicago',
  ),
  ManualLocationPreset(
    id: 'houston_us',
    city: 'Houston',
    country: 'United States',
    coordinates: Coordinates(latitude: 29.7604, longitude: -95.3698),
    timeZoneId: 'America/Chicago',
  ),
  ManualLocationPreset(
    id: 'new_york_us',
    city: 'New York',
    country: 'United States',
    coordinates: Coordinates(latitude: 40.7128, longitude: -74.0060),
    timeZoneId: 'America/New_York',
  ),
  ManualLocationPreset(
    id: 'los_angeles_us',
    city: 'Los Angeles',
    country: 'United States',
    coordinates: Coordinates(latitude: 34.0522, longitude: -118.2437),
    timeZoneId: 'America/Los_Angeles',
  ),
  ManualLocationPreset(
    id: 'toronto_ca',
    city: 'Toronto',
    country: 'Canada',
    coordinates: Coordinates(latitude: 43.6532, longitude: -79.3832),
    timeZoneId: 'America/Toronto',
  ),
  ManualLocationPreset(
    id: 'mexico_city_mx',
    city: 'Mexico City',
    country: 'Mexico',
    coordinates: Coordinates(latitude: 19.4326, longitude: -99.1332),
    timeZoneId: 'America/Mexico_City',
  ),
  ManualLocationPreset(
    id: 'sao_paulo_br',
    city: 'Sao Paulo',
    country: 'Brazil',
    coordinates: Coordinates(latitude: -23.5558, longitude: -46.6396),
    timeZoneId: 'America/Sao_Paulo',
  ),
  ManualLocationPreset(
    id: 'london_uk',
    city: 'London',
    country: 'United Kingdom',
    coordinates: Coordinates(latitude: 51.5074, longitude: -0.1278),
    timeZoneId: 'Europe/London',
  ),
  ManualLocationPreset(
    id: 'istanbul_tr',
    city: 'Istanbul',
    country: 'Turkey',
    coordinates: Coordinates(latitude: 41.0082, longitude: 28.9784),
    timeZoneId: 'Europe/Istanbul',
  ),
  ManualLocationPreset(
    id: 'cairo_eg',
    city: 'Cairo',
    country: 'Egypt',
    coordinates: Coordinates(latitude: 30.0444, longitude: 31.2357),
    timeZoneId: 'Africa/Cairo',
  ),
  ManualLocationPreset(
    id: 'lagos_ng',
    city: 'Lagos',
    country: 'Nigeria',
    coordinates: Coordinates(latitude: 6.5244, longitude: 3.3792),
    timeZoneId: 'Africa/Lagos',
  ),
  ManualLocationPreset(
    id: 'johannesburg_za',
    city: 'Johannesburg',
    country: 'South Africa',
    coordinates: Coordinates(latitude: -26.2041, longitude: 28.0473),
    timeZoneId: 'Africa/Johannesburg',
  ),
  ManualLocationPreset(
    id: 'makkah_sa',
    city: 'Makkah',
    country: 'Saudi Arabia',
    coordinates: Coordinates(latitude: 21.3891, longitude: 39.8579),
    timeZoneId: 'Asia/Riyadh',
  ),
  ManualLocationPreset(
    id: 'dubai_ae',
    city: 'Dubai',
    country: 'United Arab Emirates',
    coordinates: Coordinates(latitude: 25.2048, longitude: 55.2708),
    timeZoneId: 'Asia/Dubai',
  ),
  ManualLocationPreset(
    id: 'tehran_ir',
    city: 'Tehran',
    country: 'Iran',
    coordinates: Coordinates(latitude: 35.6892, longitude: 51.3890),
    timeZoneId: 'Asia/Tehran',
  ),
  ManualLocationPreset(
    id: 'karachi_pk',
    city: 'Karachi',
    country: 'Pakistan',
    coordinates: Coordinates(latitude: 24.8607, longitude: 67.0011),
    timeZoneId: 'Asia/Karachi',
  ),
  ManualLocationPreset(
    id: 'delhi_in',
    city: 'Delhi',
    country: 'India',
    coordinates: Coordinates(latitude: 28.6139, longitude: 77.2090),
    timeZoneId: 'Asia/Kolkata',
  ),
  ManualLocationPreset(
    id: 'dhaka_bd',
    city: 'Dhaka',
    country: 'Bangladesh',
    coordinates: Coordinates(latitude: 23.8103, longitude: 90.4125),
    timeZoneId: 'Asia/Dhaka',
  ),
  ManualLocationPreset(
    id: 'kuala_lumpur_my',
    city: 'Kuala Lumpur',
    country: 'Malaysia',
    coordinates: Coordinates(latitude: 3.1390, longitude: 101.6869),
    timeZoneId: 'Asia/Kuala_Lumpur',
  ),
  ManualLocationPreset(
    id: 'jakarta_id',
    city: 'Jakarta',
    country: 'Indonesia',
    coordinates: Coordinates(latitude: -6.2088, longitude: 106.8456),
    timeZoneId: 'Asia/Jakarta',
  ),
  ManualLocationPreset(
    id: 'singapore_sg',
    city: 'Singapore',
    country: 'Singapore',
    coordinates: Coordinates(latitude: 1.3521, longitude: 103.8198),
    timeZoneId: 'Asia/Singapore',
  ),
  ManualLocationPreset(
    id: 'sydney_au',
    city: 'Sydney',
    country: 'Australia',
    coordinates: Coordinates(latitude: -33.8688, longitude: 151.2093),
    timeZoneId: 'Australia/Sydney',
  ),
];

ManualLocationPreset manualLocationPresetById(String id) {
  for (final ManualLocationPreset preset in kManualLocationPresets) {
    if (preset.id == id) {
      return preset;
    }
  }
  return kManualLocationPresets.first;
}

ManualLocationPreset closestManualLocationPreset(Coordinates coordinates) {
  ManualLocationPreset bestMatch = kManualLocationPresets.first;
  double bestDistance = double.infinity;

  for (final ManualLocationPreset preset in kManualLocationPresets) {
    final double latitudeDelta =
        coordinates.latitude - preset.coordinates.latitude;
    final double longitudeDelta =
        coordinates.longitude - preset.coordinates.longitude;
    final double distance = math.pow(latitudeDelta, 2).toDouble() +
        math.pow(longitudeDelta, 2).toDouble();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestMatch = preset;
    }
  }

  return bestMatch;
}

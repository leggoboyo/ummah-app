import 'package:core/core.dart';

class AppLocationState {
  const AppLocationState({
    required this.coordinates,
    required this.summary,
    this.bannerMessage,
  });

  final Coordinates coordinates;
  final String summary;
  final String? bannerMessage;
}

class QiblaDirection {
  const QiblaDirection({
    required this.bearingFromTrueNorth,
  });

  final double bearingFromTrueNorth;

  double relativeToHeading(double heading) {
    return (bearingFromTrueNorth - heading + 360.0) % 360.0;
  }
}

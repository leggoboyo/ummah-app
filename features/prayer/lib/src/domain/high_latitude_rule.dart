enum HighLatitudeRule {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
}

extension HighLatitudeRuleX on HighLatitudeRule {
  String get label {
    switch (this) {
      case HighLatitudeRule.middleOfTheNight:
        return 'Middle of the night';
      case HighLatitudeRule.seventhOfTheNight:
        return 'Seventh of the night';
      case HighLatitudeRule.twilightAngle:
        return 'Twilight angle';
    }
  }
}

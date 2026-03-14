enum FiqhTradition {
  sunni,
  shia,
}

enum SchoolOfThought {
  hanafi,
  maliki,
  shafii,
  hanbali,
  jafari,
}

enum AsrMethod {
  standard,
  hanafi,
}

class FiqhProfile {
  const FiqhProfile({
    required this.tradition,
    required this.school,
  }) : assert(
          (tradition == FiqhTradition.sunni &&
                  school != SchoolOfThought.jafari) ||
              (tradition == FiqhTradition.shia &&
                  school == SchoolOfThought.jafari),
          'School does not match selected tradition.',
        );

  final FiqhTradition tradition;
  final SchoolOfThought school;

  static const FiqhProfile defaultSunni = FiqhProfile(
    tradition: FiqhTradition.sunni,
    school: SchoolOfThought.shafii,
  );

  static const FiqhProfile defaultShia = FiqhProfile(
    tradition: FiqhTradition.shia,
    school: SchoolOfThought.jafari,
  );

  String get label {
    switch (school) {
      case SchoolOfThought.hanafi:
        return 'Sunni - Hanafi';
      case SchoolOfThought.maliki:
        return 'Sunni - Maliki';
      case SchoolOfThought.shafii:
        return 'Sunni - Shafi‘i';
      case SchoolOfThought.hanbali:
        return 'Sunni - Hanbali';
      case SchoolOfThought.jafari:
        return 'Shia - Ja‘fari';
    }
  }

  AsrMethod get defaultAsrMethod {
    return school == SchoolOfThought.hanafi
        ? AsrMethod.hanafi
        : AsrMethod.standard;
  }
}

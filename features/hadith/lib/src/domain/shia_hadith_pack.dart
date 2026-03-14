enum ShiaHadithPackStatus {
  comingSoon,
  available,
}

class ShiaHadithPackAvailability {
  const ShiaHadithPackAvailability({
    required this.status,
    required this.providerName,
    required this.message,
  });

  final ShiaHadithPackStatus status;
  final String providerName;
  final String message;
}

abstract interface class ShiaHadithPackProvider {
  Future<ShiaHadithPackAvailability> getAvailability();
}

class PlaceholderShiaHadithPackProvider implements ShiaHadithPackProvider {
  const PlaceholderShiaHadithPackProvider();

  @override
  Future<ShiaHadithPackAvailability> getAvailability() async {
    return const ShiaHadithPackAvailability(
      status: ShiaHadithPackStatus.comingSoon,
      providerName: 'Licensed Shia partner pending',
      message:
          'Shia Hadith Pack is coming. It requires licensed content before it can be shipped respectfully and responsibly.',
    );
  }
}

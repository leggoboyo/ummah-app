enum UiPerformanceMode {
  standard,
  lean;

  String get label {
    switch (this) {
      case UiPerformanceMode.standard:
        return 'Standard';
      case UiPerformanceMode.lean:
        return 'Lean';
    }
  }
}

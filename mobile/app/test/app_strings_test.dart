import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_mobile_app/src/app/app_strings.dart';

void main() {
  test('falls back to English when the locale is unsupported', () {
    final AppStrings strings = AppStrings.forCode('fr');

    expect(strings.languageCode, 'en');
    expect(strings.homeTab, 'Home');
    expect(strings.isRtl, isFalse);
  });

  test('marks Arabic and Urdu strings as RTL', () {
    expect(AppStrings.forCode('ar').isRtl, isTrue);
    expect(AppStrings.forCode('ur').isRtl, isTrue);
    expect(AppStrings.forCode('en').isRtl, isFalse);
  });
}

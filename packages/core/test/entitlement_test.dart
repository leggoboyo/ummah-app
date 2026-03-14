import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('mega bundle unlocks other entitlements implicitly', () {
    final bool unlocked = hasEntitlement(
      <AppEntitlement>{AppEntitlement.megaBundle},
      AppEntitlement.aiQuran,
    );

    expect(unlocked, isTrue);
  });
}

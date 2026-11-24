import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mihrab/application/settings.dart';
import 'package:mihrab/application/onboarding.dart';

void main() {
  test('new installation completes onboarding persistently', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(onboardingProvider), isFalse);
    await container.read(onboardingProvider.notifier).complete();
    expect(container.read(onboardingProvider), isTrue);
    expect(prefs.getBool(OnboardingController.key), isTrue);
  });
  test('existing city setting avoids forced onboarding', () async {
    SharedPreferences.setMockInitialValues({'city': 1});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(onboardingProvider), isTrue);
  });
}

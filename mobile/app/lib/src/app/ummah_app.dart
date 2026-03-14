import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../bootstrap/app_controller.dart';
import '../home/home_shell.dart';
import '../onboarding/onboarding_flow.dart';
import 'app_strings.dart';

class UmmahApp extends StatelessWidget {
  const UmmahApp({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final AppStrings strings = AppStrings.forCode(controller.languageCode);
        return MaterialApp(
          title: strings.appName,
          debugShowCheckedModeBanner: false,
          locale: Locale(controller.languageCode),
          supportedLocales: const <Locale>[
            Locale('en'),
            Locale('ar'),
            Locale('ur'),
          ],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: _buildTheme(),
          builder: (BuildContext context, Widget? child) {
            final Widget currentChild = _AppBackdrop(
              child: child ?? const SizedBox.shrink(),
            );

            if (!controller.environment.showBuildBanner) {
              return currentChild;
            }

            return Banner(
              message: controller.environment.flavor.label,
              location: BannerLocation.topEnd,
              child: currentChild,
            );
          },
          home: !controller.isReady
              ? const _BootstrapScreen()
              : controller.onboardingComplete
                  ? HomeShell(controller: controller)
                  : OnboardingFlow(controller: controller),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    const Color seed = Color(0xFF0D6F59);
    const Color cloud = Color(0xFFF9F7F2);
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: cloud,
      surfaceContainerLow: const Color(0xFFFDFBF7),
      outlineVariant: const Color(0xFFD7D0C1),
    );
    final ThemeData base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
    final TextTheme textTheme = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 33,
        fontWeight: FontWeight.w700,
        height: 1.04,
        letterSpacing: -0.7,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        height: 1.45,
        color: const Color(0xFF5E655F),
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFE9F1EA),
        side: BorderSide.none,
        selectedColor: colorScheme.primaryContainer,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.labelLarge?.copyWith(
          fontSize: 12,
          color: const Color(0xFF19463D),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.4,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        indicatorColor: colorScheme.primaryContainer,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
      splashFactory: InkRipple.splashFactory,
      extensions: const <ThemeExtension<dynamic>>[],
    );
  }
}

class _AppBackdrop extends StatelessWidget {
  const _AppBackdrop({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF6F1E6),
            Color(0xFFF3EEE1),
            Color(0xFFF8F7F1),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFF6F1E6),
              Color(0xFFF4EFE2),
              Color(0xFFF8F7F1),
            ],
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

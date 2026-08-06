import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/app_constant.dart';
import 'core/config/app_identity_state.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_color.dart';
import 'core/theme/app_theme.dart';
import 'core/network/network_providers.dart';
import 'features/health/presentation/health_providers.dart';

class LunaApp extends StatelessWidget {
  LunaApp({required this.config, super.key})
    : _router = AppRouter(config: config);

  final AppConfig config;
  final AppRouter _router;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(config.apiClient),
      appIdentityStateProvider.overrideWithValue(config.identityState),
      socketServiceProvider.overrideWithValue(config.socketService),
    ],
    child: MaterialApp.router(
      title: AppConstant.appName,
      locale: const Locale(AppConstant.defaultLocale),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light, // Force light mode to show the vibrant pastel Friendly UI
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: AppColor.pageGradient(Theme.of(context).brightness),
        ),
        child: child,
      ),
      routerConfig: _router.router,
    ),
  );
}

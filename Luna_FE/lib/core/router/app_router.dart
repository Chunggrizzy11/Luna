import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_complete_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/splash/presentation/bootstrap_error_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../config/app_config.dart';
import '../config/app_identity_state.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter({required AppConfig config})
    : router = GoRouter(
        initialLocation: AppRoutes.splash,
        refreshListenable: config.identityState,
        redirect: (context, state) => redirectPath(
          status: config.identityState.status,
          location: state.uri.path,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => OnboardingPage(
              controller: config.onboardingController,
              onReady: (identity) {
                config.identityState.setPresent(identity);
                context.go(AppRoutes.home);
              },
            ),
          ),
          GoRoute(
            path: AppRoutes.bootstrapError,
            builder: (context, state) =>
                BootstrapErrorPage(identityState: config.identityState),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                OnboardingCompletePage(identityState: config.identityState),
          ),
        ],
      );

  final GoRouter router;

  static String? redirectPath({
    required AppIdentityStatus status,
    required String location,
  }) {
    if (status == AppIdentityStatus.error) {
      return location == AppRoutes.bootstrapError
          ? null
          : AppRoutes.bootstrapError;
    }
    if (status == AppIdentityStatus.missing) {
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }
    if (location == AppRoutes.onboarding ||
        location == AppRoutes.splash ||
        location == AppRoutes.bootstrapError) {
      return AppRoutes.home;
    }
    return null;
  }
}

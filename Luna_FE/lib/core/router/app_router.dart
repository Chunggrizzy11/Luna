import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../shared/entities/device_identity.dart';
import '../config/app_config.dart';
import '../error/exception.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter({required AppConfig config})
    : router = GoRouter(
        initialLocation: AppRoutes.splash,
        redirect: (context, state) async {
          DeviceIdentity? identity;
          try {
            identity = await config.secureStorage.readIdentity();
          } on StorageException {
            identity = null;
          }
          return redirectPath(identity: identity, location: state.uri.path);
        },
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => OnboardingPage(
              controller: config.onboardingController,
              onReady: (_) => context.go(AppRoutes.home),
            ),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => config.homeBuilder(context),
          ),
        ],
      );

  final GoRouter router;

  static String? redirectPath({
    required DeviceIdentity? identity,
    required String location,
  }) {
    if (identity == null) {
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }
    if (location == AppRoutes.onboarding) return AppRoutes.home;
    if (location == AppRoutes.splash) return AppRoutes.home;
    return null;
  }
}

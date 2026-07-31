import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/config/app_identity_state.dart';
import 'package:luna_fe/core/router/app_router.dart';
import 'package:luna_fe/core/router/app_routes.dart';

void main() {
  test('redirects a device without secure identity to onboarding', () {
    expect(
      AppRouter.redirectPath(
        status: AppIdentityStatus.missing,
        location: AppRoutes.home,
      ),
      AppRoutes.onboarding,
    );
  });

  test('does not redirect an identified device to onboarding', () {
    expect(
      AppRouter.redirectPath(
        status: AppIdentityStatus.present,
        location: AppRoutes.home,
      ),
      isNull,
    );
  });

  test('redirects an identified device away from onboarding', () {
    expect(
      AppRouter.redirectPath(
        status: AppIdentityStatus.present,
        location: AppRoutes.onboarding,
      ),
      AppRoutes.home,
    );
  });

  test('allows onboarding itself when secure identity is absent', () {
    expect(
      AppRouter.redirectPath(
        status: AppIdentityStatus.missing,
        location: AppRoutes.onboarding,
      ),
      isNull,
    );
  });

  test('routes storage errors to bootstrap error instead of onboarding', () {
    expect(
      AppRouter.redirectPath(
        status: AppIdentityStatus.error,
        location: AppRoutes.onboarding,
      ),
      AppRoutes.bootstrapError,
    );
    expect(
      AppRouter.redirectPath(
        status: AppIdentityStatus.error,
        location: AppRoutes.bootstrapError,
      ),
      isNull,
    );
  });
}

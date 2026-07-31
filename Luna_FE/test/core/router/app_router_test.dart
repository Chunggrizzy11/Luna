import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/router/app_router.dart';
import 'package:luna_fe/core/router/app_routes.dart';
import 'package:luna_fe/shared/entities/device_identity.dart';
import 'package:luna_fe/shared/enums/device_role.dart';

void main() {
  test('redirects a device without secure identity to onboarding', () {
    expect(
      AppRouter.redirectPath(identity: null, location: AppRoutes.home),
      AppRoutes.onboarding,
    );
  });

  test('does not redirect an identified device to onboarding', () {
    expect(
      AppRouter.redirectPath(
        identity: const DeviceIdentity(
          deviceId: 'device-1',
          token: 'secret',
          role: DeviceRole.owner,
        ),
        location: AppRoutes.home,
      ),
      isNull,
    );
  });

  test('redirects an identified device away from onboarding', () {
    expect(
      AppRouter.redirectPath(
        identity: const DeviceIdentity(
          deviceId: 'device-1',
          token: 'secret',
          role: DeviceRole.owner,
        ),
        location: AppRoutes.onboarding,
      ),
      AppRoutes.home,
    );
  });

  test('allows onboarding itself when secure identity is absent', () {
    expect(
      AppRouter.redirectPath(identity: null, location: AppRoutes.onboarding),
      isNull,
    );
  });
}

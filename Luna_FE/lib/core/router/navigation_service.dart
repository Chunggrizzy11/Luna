import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  const NavigationService(this.router);

  final GoRouter router;

  void go(String location, {Object? extra}) =>
      router.go(location, extra: extra);

  Future<T?> push<T extends Object?>(String location, {Object? extra}) =>
      router.push<T>(location, extra: extra);

  void pop<T extends Object?>([T? result]) {
    if (router.canPop()) router.pop<T>(result);
  }

  static GoRouter of(BuildContext context) => GoRouter.of(context);
}

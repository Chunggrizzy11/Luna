abstract final class ApiEndpoint {
  static const registerDevice = '/devices/register';
  static const currentDevice = '/devices/me';

  static const publicPaths = <String>{registerDevice};
}

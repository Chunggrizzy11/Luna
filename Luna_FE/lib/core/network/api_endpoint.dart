abstract final class ApiEndpoint {
  static const registerDevice = '/devices/register';
  static const currentDevice = '/devices/me';
  static const devicePushToken = '/devices/push-token';
  static const cycles = '/cycles';
  static const currentCycle = '/cycles/current';
  static const startCycle = '/cycles/start';
  static const endCycle = '/cycles/end';
  static const calendar = '/calendar';
  static const dashboard = '/health/dashboard';
  static const careToday = '/health/care/today';
  static const journal = '/health/journal';
  static const pairingCode = '/pairing/code';
  static const pairingJoin = '/pairing/join';
  static const pairingUnpair = '/pairing/unpair';
  static const pairingStatus = '/pairing/status';
  static const notifications = '/notifications';

  static String mood(String date) => '/moods/$date';
  static String symptoms(String date) => '/symptoms/$date';
  static String note(String date) => '/notes/$date';
  static String deleteJournal(String date) => '/health/journal/$date';

  static const publicPaths = <String>{registerDevice};
}

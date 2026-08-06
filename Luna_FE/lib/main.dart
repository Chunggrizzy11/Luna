import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/config/app_initializer.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (maybe not configured yet): $e');
  }

  await initializeDateFormatting('vi');
  final config = await AppInitializer.initialize();
  runApp(LunaApp(config: config));
}

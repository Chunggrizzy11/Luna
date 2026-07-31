import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppInitializer.initialize(
    homeBuilder: (_) => const Center(child: Text('Luna')),
  );
  runApp(ProviderScope(child: LunaApp(config: config)));
}

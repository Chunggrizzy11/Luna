import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class LunaApp extends StatelessWidget {
  const LunaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Luna',
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Scaffold(body: Center(child: Text('Luna'))),
      );
}

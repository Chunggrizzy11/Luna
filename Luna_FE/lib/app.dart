import 'package:flutter/material.dart';

class LunaApp extends StatelessWidget {
  const LunaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Luna',
        home: const Scaffold(body: Center(child: Text('Luna'))),
      );
}

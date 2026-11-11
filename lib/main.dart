import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/slot_machine/presentation/screens/slot_machine_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CiupaneleApp()));
}

class CiupaneleApp extends StatelessWidget {
  const CiupaneleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ciupanele',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFEB6B43),
        brightness: Brightness.dark,
        surface: const Color(0xFF201A27),
      ),
      scaffoldBackgroundColor: const Color(0xFF17131D),
      fontFamily: 'Roboto',
    ),
    home: const SlotMachineScreen(),
  );
}

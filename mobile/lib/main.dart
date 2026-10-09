import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClimatwinApp());
}

class ClimatwinApp extends StatelessWidget {
  const ClimatwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CLIMATWIN',
      debugShowCheckedModeBanner: false,
      theme: ClimatwinTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/navigation.dart';
import 'core/auth_service.dart';
import 'core/firestore_service.dart';
import 'core/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Core initialize notice: $e');
  }
  AuthService.instance.initialize();
  FirestoreService.instance.initialize();
  await NotificationService.instance.initialize();
  runApp(const ClimatwinApp());
}

class ClimatwinApp extends StatelessWidget {
  const ClimatwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CLIMATWIN',
      debugShowCheckedModeBanner: false,
      theme: ClimatwinTheme.darkTheme,
      darkTheme: ClimatwinTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainNavigationShell(),
    );
  }
}

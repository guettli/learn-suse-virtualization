import 'package:flutter/material.dart';
import 'screens/deck_selection_screen.dart';
import 'services/foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ForegroundServiceManager.initialize();

  runApp(const HandsFreeAnkiApp());
}

class HandsFreeAnkiApp extends StatelessWidget {
  const HandsFreeAnkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hands-Free Flashcards',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const DeckSelectionScreen(),
    );
  }
}

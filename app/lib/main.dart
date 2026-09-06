import 'package:flutter/material.dart';
import 'package:salah/screens/home_screen.dart';
import 'package:salah/theme.dart';

void main() {
  runApp(const SalahApp());
}

class SalahApp extends StatelessWidget {
  const SalahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salah & Gratitude',
      debugShowCheckedModeBanner: false,
      theme: buildGardenTheme(),
      home: const HomeScreen(),
    );
  }
}

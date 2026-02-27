import 'package:flutter/material.dart';
import '../services/language_manager.dart';
import '../services/app_language_state.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  @override
  void initState() {
    super.initState();
    AppLanguageState.addListener(_onLanguageChange);
  }

  @override
  void dispose() {
    AppLanguageState.removeListener(_onLanguageChange);
    super.dispose();
  }

  void _onLanguageChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        LanguageManager.getString('welcome', AppLanguageState.currentLanguage),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
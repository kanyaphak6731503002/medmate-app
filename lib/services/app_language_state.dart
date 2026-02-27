import 'package:flutter/material.dart';
import 'language_manager.dart';

class AppLanguageState {
  static String currentLanguage = LanguageManager.ENGLISH;
  static List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  static void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  static void notifyLanguageChange() {
    for (var listener in _listeners) {
      listener();
    }
  }

  static void changeLanguage(String language) {
    currentLanguage = language;
    notifyLanguageChange();
  }
}

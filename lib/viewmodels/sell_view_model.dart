import 'package:flutter/material.dart';

class ShellViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeTab(int index) {
    if (_selectedIndex == index) return;

    _selectedIndex = index;
    notifyListeners();
  }
}
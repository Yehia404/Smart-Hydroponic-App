import 'package:flutter/material.dart';
import '../view/dashboard/home_overview_screen.dart';
import '../view/dashboard/sensor_monitoring_screen.dart';
import '../view/controls/control_panel_screen.dart';

class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeOverviewScreen(),
    SensorMonitoringScreen(),
    ControlPanelScreen(),
  ];

  Widget get currentWidget => _widgetOptions.elementAt(_selectedIndex);

  void onItemTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
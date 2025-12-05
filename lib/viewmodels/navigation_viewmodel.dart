import 'package:flutter/material.dart';
import 'package:smart_hydroponic_app/view/dashboard/dashboard_screen.dart';
import '../view/dashboard/sensor_monitoring_screen.dart';
import '../view/controls/control_panel_screen.dart';

class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    SensorMonitoringScreen(),
    ControlPanelScreen(),
  ];

  Widget get currentWidget => _widgetOptions.elementAt(_selectedIndex);

  void onItemTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
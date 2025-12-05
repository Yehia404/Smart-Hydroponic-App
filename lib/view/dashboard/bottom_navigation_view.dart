import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/navigation_viewmodel.dart';
class BottomNavigationView extends StatelessWidget {
  const BottomNavigationView({super.key});
  @override
  Widget build(BuildContext context) {

  final viewModel = Provider.of<NavigationViewModel>(context);

    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sensors),
          label: 'Sensors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.toggle_on_outlined),
          label: 'Controls',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'Analytics',
        ),
      ],
      currentIndex: viewModel.selectedIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: viewModel.onItemTapped,
    );
  }
}
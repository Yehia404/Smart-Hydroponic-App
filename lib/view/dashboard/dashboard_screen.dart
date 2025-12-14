import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'alerts_notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'bottom_navigation_view.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../viewmodels/tts_viewmodel.dart';
import '../../viewmodels/speech_recognition_viewmodel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('SMART Hydroponic'),
        actions: [
          Consumer<SpeechRecognitionViewModel>(
            builder: (context, speechViewModel, child) {
              return IconButton(
                icon: Icon(
                  speechViewModel.isListening ? Icons.mic : Icons.mic_none,
                  color: speechViewModel.isListening ? Colors.red : null,
                ),
                tooltip: speechViewModel.isListening ? 'Stop Listening' : 'Voice Command',
                onPressed: () => speechViewModel.toggleListening(context),
              );
            },
          ),
          Consumer<TtsViewModel>(
            builder: (context, ttsViewModel, child) {
              return IconButton(
                icon: Icon(
                  ttsViewModel.isSpeaking ? Icons.volume_off : Icons.volume_up,
                ),
                tooltip: ttsViewModel.isSpeaking ? 'Stop Reading' : 'Read Screen',
                onPressed: () => ttsViewModel.speakCurrentScreen(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlertsNotificationsScreen(),
                ),
              );
            },

          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<NavigationViewModel>(
        builder: (context, viewModel, child) => viewModel.currentWidget,
      ),
      bottomNavigationBar: const BottomNavigationView(),
            );
          }
}

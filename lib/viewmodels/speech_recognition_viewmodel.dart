import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/services/speech_recognition_service.dart';
import 'actuator_control_viewmodel.dart';

class SpeechRecognitionViewModel extends ChangeNotifier {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String _partialText = '';
  String? _errorMessage;
  BuildContext? _lastContext;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  String get partialText => _partialText;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final success = await _speechService.initialize();
      _isInitialized = success;
      
      // Set up callbacks
      _speechService.onListeningStart = () {
        _isListening = true;
        _errorMessage = null;
        notifyListeners();
      };
      
      _speechService.onListeningStop = () {
        _isListening = false;
        notifyListeners();
      };
      
      _speechService.onResult = (text) async {
        _recognizedText = text;
        _partialText = '';
        notifyListeners();
        
        // Automatically process the command when recognized
        if (text.isNotEmpty && _lastContext != null) {
          await processCommand(_lastContext!, text);
        }
      };
      
      _speechService.onPartialResult = (text) {
        _partialText = text;
        notifyListeners();
      };
      
      _speechService.onError = (error) {
        _errorMessage = error;
        _isListening = false;
        notifyListeners();
      };
      
      notifyListeners();
    } catch (e) {
      print('Speech recognition initialization error: $e');
      _errorMessage = 'Failed to initialize speech recognition';
      notifyListeners();
    }
  }

  Future<void> startListening(BuildContext context) async {
    if (!_isInitialized) await initialize();
    
    if (!_isInitialized) {
      _errorMessage = 'Speech recognition not available';
      notifyListeners();
      return;
    }

    _lastContext = context;
    _recognizedText = '';
    _partialText = '';
    _errorMessage = null;
    
    await _speechService.startListening();
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
  }

  Future<void> toggleListening(BuildContext context) async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening(context);
    }
  }

  Future<void> processCommand(BuildContext context, String command) async {
    final lowerCommand = command.toLowerCase().trim();
    print('🎯 Processing command: $lowerCommand');

    try {
      final actuatorViewModel = Provider.of<ActuatorControlViewModel>(context, listen: false);

      // Pump control commands
      if (lowerCommand.contains('turn on pump') || 
          lowerCommand.contains('start pump') || 
          lowerCommand.contains('pump on')) {
        actuatorViewModel.togglePump(true);
        _showFeedback(context, '✅ Water pump turned ON');
      } 
      else if (lowerCommand.contains('turn off pump') || 
               lowerCommand.contains('stop pump') || 
               lowerCommand.contains('pump off')) {
        actuatorViewModel.togglePump(false);
        _showFeedback(context, '✅ Water pump turned OFF');
      }
      
      // Lights control commands
      else if (lowerCommand.contains('turn on lights') || 
               lowerCommand.contains('lights on') || 
               lowerCommand.contains('turn on light')) {
        actuatorViewModel.toggleLights(true);
        _showFeedback(context, '✅ Grow lights turned ON');
      }
      else if (lowerCommand.contains('turn off lights') || 
               lowerCommand.contains('lights off') || 
               lowerCommand.contains('turn off light')) {
        actuatorViewModel.toggleLights(false);
        _showFeedback(context, '✅ Grow lights turned OFF');
      }
      
      // Fan control commands
      else if (lowerCommand.contains('turn on fans') || 
               lowerCommand.contains('fans on') || 
               lowerCommand.contains('turn on fan')) {
        actuatorViewModel.toggleFans(true);
        _showFeedback(context, '✅ Ventilation fans turned ON');
      }
      else if (lowerCommand.contains('turn off fans') || 
               lowerCommand.contains('fans off') || 
               lowerCommand.contains('turn off fan')) {
        actuatorViewModel.toggleFans(false);
        _showFeedback(context, '✅ Ventilation fans turned OFF');
      }
      
      // Turn everything on/off
      else if (lowerCommand.contains('turn everything on') || 
               lowerCommand.contains('turn all on')) {
        actuatorViewModel.togglePump(true);
        actuatorViewModel.toggleLights(true);
        actuatorViewModel.toggleFans(true);
        _showFeedback(context, '✅ All systems turned ON');
      }
      else if (lowerCommand.contains('turn everything off') || 
               lowerCommand.contains('turn all off')) {
        actuatorViewModel.togglePump(false);
        actuatorViewModel.toggleLights(false);
        actuatorViewModel.toggleFans(false);
        _showFeedback(context, '✅ All systems turned OFF');
      }
      
      // Emergency stop
      else if (lowerCommand.contains('emergency stop') || 
               lowerCommand.contains('stop everything')) {
        actuatorViewModel.emergencyStop();
        _showFeedback(context, '🚨 Emergency stop activated');
      }
      
      else {
        _showFeedback(context, '❓ Command not recognized. Try: "turn on pump", "lights off", etc.');
      }
    } catch (e) {
      print('Error processing command: $e');
      _showFeedback(context, '❌ Error executing command');
    }
  }

  void _showFeedback(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}

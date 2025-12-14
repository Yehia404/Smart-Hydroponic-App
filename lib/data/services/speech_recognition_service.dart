import 'package:speech_to_text/speech_to_text.dart';

/// Service class to handle Speech-to-Text functionality.
/// Implements the Singleton pattern to ensure a single instance manages the speech recognition resource.
class SpeechRecognitionService {
  // Singleton instance
  static final SpeechRecognitionService _instance =
      SpeechRecognitionService._internal();

  // Factory constructor to return the singleton instance
  factory SpeechRecognitionService() => _instance;

  // Private constructor
  SpeechRecognitionService._internal();

  // Core SpeechToText instance
  final SpeechToText _speechToText = SpeechToText();

  // State variables
  bool _isInitialized = false;
  bool _isListening = false;

  // Getters for state
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  // Callbacks for various speech events
  Function(String)? onResult; // Called when a final result is received
  Function(String)?
  onPartialResult; // Called when partial results are available
  Function()? onListeningStart; // Called when listening begins
  Function()? onListeningStop; // Called when listening ends
  Function(String)? onError; // Called when an error occurs

  /// Initializes the speech recognition service.
  /// Returns true if initialization is successful, false otherwise.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          print('❌ Speech recognition error: ${error.errorMsg}');
          _isListening = false;
          onError?.call(error.errorMsg);
        },
        onStatus: (status) {
          print('🎤 Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onListeningStop?.call();
          }
        },
      );

      if (_isInitialized) {
        print('✅ Speech recognition initialized successfully');
      } else {
        print('❌ Speech recognition initialization failed');
      }

      return _isInitialized;
    } catch (e) {
      print('❌ Speech recognition initialization error: $e');
      return false;
    }
  }

  /// Starts listening for speech input.
  /// [locale] specifies the language to listen for (default is 'en_US').
  Future<void> startListening({String locale = 'en_US'}) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      print('⚠️ Already listening');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;

          if (result.finalResult) {
            print('🎯 Final result: $recognizedWords');
            onResult?.call(recognizedWords);
          } else {
            print('📝 Partial result: $recognizedWords');
            onPartialResult?.call(recognizedWords);
          }
        },
        listenFor: const Duration(
          seconds: 30,
        ), // Stop listening after 30 seconds of silence
        pauseFor: const Duration(
          seconds: 3,
        ), // Pause after 3 seconds of silence
        partialResults: true, // Enable partial results
        localeId: locale,
        cancelOnError: false,
      );

      _isListening = true;
      onListeningStart?.call();
      print('🎤 Started listening...');
    } catch (e) {
      print('❌ Error starting speech recognition: $e');
      onError?.call(e.toString());
    }
  }

  /// Stops listening for speech.
  /// Processes any pending results.
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      onListeningStop?.call();
      print('🛑 Stopped listening');
    } catch (e) {
      print('❌ Error stopping speech recognition: $e');
    }
  }

  /// Cancels the current listening session.
  /// Discards any pending results.
  Future<void> cancel() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      onListeningStop?.call();
      print('🚫 Cancelled listening');
    } catch (e) {
      print('❌ Error cancelling speech recognition: $e');
    }
  }

  /// Retrieves the list of available locales supported by the device.
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) return [];
    final locales = await _speechToText.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  /// Disposes of the service resources.
  void dispose() {
    _speechToText.stop();
  }
}

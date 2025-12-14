import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  Function()? onComplete;
  Function()? onStart;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        print('🎤 TTS Started');
        _isSpeaking = true;
        onStart?.call();
      });

      _flutterTts.setCompletionHandler(() {
        print('✅ TTS Completed');
        _isSpeaking = false;
        onComplete?.call();
      });

      _flutterTts.setCancelHandler(() {
        print('🛑 TTS Cancelled');
        _isSpeaking = false;
        onComplete?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        print("❌ TTS Error: $msg");
        _isSpeaking = false;
        onComplete?.call();
      });

      _isInitialized = true;
      print("✅ TTS initialized successfully");
    } catch (e) {
      print("❌ TTS initialization failed: $e");
      print("💡 Run: flutter clean && flutter pub get && flutter run");
      rethrow;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      print('⚠️ TTS not initialized, initializing now...');
      await initialize();
    }
    
    if (text.isEmpty) {
      print('⚠️ TTS: Empty text provided');
      return;
    }

    print('🔊 TTS Speaking: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
    final result = await _flutterTts.speak(text);
    print('📢 TTS speak() result: $result');
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  Future<void> pause() async {
    if (!_isInitialized) return;
    await _flutterTts.pause();
  }

  void dispose() {
    _flutterTts.stop();
  }
}

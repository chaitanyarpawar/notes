import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechProvider extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool get isListening => _isListening;

  String _lastResult = '';
  String get lastResult => _lastResult;

  String _status = 'idle';
  String get status => _status; // idle | listening | notAvailable | error

  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onStatus: (s) {
          _status = s;
          notifyListeners();
        },
        onError: (e) {
          _status = 'error:${e.errorMsg}';
          notifyListeners();
        },
      );
      if (!available) {
        _status = 'notAvailable';
        notifyListeners();
      }
      return available;
    } catch (_) {
      _status = 'error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> startListening({String localeId = 'en_US'}) async {
    final ok = await initialize();
    if (!ok) return false;
    _isListening = true;
    _status = 'listening';
    notifyListeners();
    await _speech.listen(
      onResult: (result) {
        _lastResult = result.recognizedWords;
        notifyListeners();
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
      ),
      localeId: localeId,
    );
    return true;
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } finally {
      _isListening = false;
      if (_status.startsWith('listening')) _status = 'idle';
      notifyListeners();
    }
  }
}

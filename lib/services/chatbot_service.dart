import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/ml_model.dart';
import 'chatbot_responses.dart';

class ChatbotService {
  ChatbotService._internal();
  static final ChatbotService instance = ChatbotService._internal();
  factory ChatbotService() => instance;

  NaiveBayesClassifier? _classifier;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Threshold confidence — di bawah ini, gunakan keyword fallback dulu.
  // Baseline seragam 7 kelas = ~14%. 0.35 memberi jarak aman dari baseline.
  static const double _confidenceThreshold = 0.35;

  // Keyword fallback: safety net untuk kalimat pendek yang kata kuncinya jelas
  // tapi model tidak cukup yakin (misal: "LOS merah" — 2 kata saja).
  static const Map<String, List<String>> _keywordFallback = {
    'los_modem_merah': [
      'los',
      'merah',
      'lampu merah',
      'ont merah',
      'kedip merah',
      'lampu pon',
    ],
    'lemot': ['lemot', 'lambat', 'pelan', 'lola', 'lelet', 'slow', 'lag'],
    'mati': [
      'mati',
      'padam',
      'tidak bisa',
      'tidak konek',
      'internet mati',
      'gak konek',
    ],
    'putus': [
      'putus',
      'disconnect',
      'nyambung',
      'putus nyambung',
      'sering putus',
      'on off',
    ],
    'sinyal_hilang': [
      'wifi hilang',
      'sinyal hilang',
      'wifi tidak muncul',
      'wifi tidak ada',
      'wifi ilang',
    ],
    'restart_ga_ngefek': [
      'restart',
      'reboot',
      'sudah restart',
      'tidak ngefek',
      'ga ngefek',
    ],
    'gangguan': [
      'gangguan',
      'maintenance',
      'area',
      'wilayah',
      'error',
      'trouble',
    ],
  };

  String? _keywordFallbackLookup(String input) {
    final lower = input.toLowerCase();
    for (final entry in _keywordFallback.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return null;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/model_params.json',
      );
      final params = json.decode(jsonString) as Map<String, dynamic>;
      _classifier = NaiveBayesClassifier.fromJson(params);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  /// Prediksi dan kembalikan hasil lengkap termasuk semua bubble teks.
  /// [onBubble] dipanggil satu per satu untuk setiap bubble yang akan dikirim,
  /// dengan jeda typing di antara bubble — ini yang membuat percakapan terasa bertahap.
  Future<ChatbotResult> predict(String userInput) async {
    if (!_isInitialized || _classifier == null) {
      return ChatbotResult(
        predictedClass: '',
        confidence: 0.0,
        bubbles: ['Chatbot sedang diinisialisasi, mohon tunggu sebentar... ⏳'],
        isDefault: true,
      );
    }

    if (userInput.trim().isEmpty) {
      return ChatbotResult(
        predictedClass: '',
        confidence: 0.0,
        bubbles: ['Silakan ketik keluhan kamu ya 😊'],
        isDefault: true,
      );
    }

    try {
      final prediction = _classifier!.predictWithConfidence(userInput);
      final predictedClass = prediction['class'] as String;
      final confidence = prediction['confidence'] as double;

      if (confidence >= _confidenceThreshold) {
        return ChatbotResult(
          predictedClass: predictedClass,
          confidence: confidence,
          bubbles: ChatbotResponses.getBubbles(predictedClass),
          isDefault: false,
        );
      }

      // Confidence rendah — coba keyword fallback
      final fallback = _keywordFallbackLookup(userInput);
      if (fallback != null) {
        return ChatbotResult(
          predictedClass: fallback,
          confidence: confidence,
          bubbles: ChatbotResponses.getBubbles(fallback),
          isDefault: false,
        );
      }

      // Tidak dikenali sama sekali
      return ChatbotResult(
        predictedClass: 'default',
        confidence: confidence,
        bubbles: ChatbotResponses.getBubbles('default'),
        isDefault: true,
      );
    } catch (e) {
      return ChatbotResult(
        predictedClass: '',
        confidence: 0.0,
        bubbles: ['Maaf, terjadi kesalahan. Silakan coba lagi ya 🙏'],
        isDefault: true,
      );
    }
  }

  List<String> getAvailableCategories() => _classifier?.classes ?? [];
}

/// Hasil prediksi lengkap dari chatbot.
class ChatbotResult {
  final String predictedClass;
  final double confidence;
  final List<String> bubbles;
  final bool isDefault;

  const ChatbotResult({
    required this.predictedClass,
    required this.confidence,
    required this.bubbles,
    required this.isDefault,
  });

  /// Kelas yang butuh CTA tiket di akhir respons.
  /// Tidak semua kelas tampilkan CTA — hanya yang memang butuh eskalasi.
  bool get shouldShowTicketCta {
    const escalationClasses = {
      'los_modem_merah',
      'mati',
      'restart_ga_ngefek',
      'putus',
      'gangguan',
      'sinyal_hilang',
    };
    return escalationClasses.contains(predictedClass) && !isDefault;
  }
}

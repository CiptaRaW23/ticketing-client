import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ml_model.dart';
import 'chatbot_responses.dart';

class ChatbotService {
  // ── Singleton ─────────────────────────────────────────────
  ChatbotService._internal();
  static final ChatbotService instance = ChatbotService._internal();
  factory ChatbotService() => instance;

  // ── State ─────────────────────────────────────────────────
  NaiveBayesClassifier? _classifier;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  static const double confidenceThreshold = 0.25;

  // ── Init ──────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/model_params.json',
      );
      final params = json.decode(jsonString) as Map<String, dynamic>;
      _classifier = NaiveBayesClassifier.fromJson(params);
      _isInitialized = true;
      print('✅ Chatbot siap. Kategori: ${_classifier!.classes}');
    } catch (e) {
      print('❌ Error loading model: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // ── Public API ────────────────────────────────────────────
  /// Return response string
  Future<String> getResponse(String userInput) async {
    final result = await getResponseWithConfidence(userInput);
    return result['response'] as String;
  }

  /// Return response + confidence + predicted class
  Future<Map<String, dynamic>> getResponseWithConfidence(
    String userInput,
  ) async {
    if (!_isInitialized || _classifier == null) {
      return _buildResult(
        response: 'Chatbot sedang diinisialisasi, mohon tunggu sebentar... ⏳',
        confidence: 0.0,
        predictedClass: '',
        isDefault: true,
      );
    }

    if (userInput.trim().isEmpty) {
      return _buildResult(
        response: 'Silakan ketik keluhan Anda. Saya siap membantu! 😊',
        confidence: 0.0,
        predictedClass: '',
        isDefault: true,
      );
    }

    try {
      final prediction = _classifier!.predictWithConfidence(userInput);
      final predictedClass = prediction['class'] as String;
      final confidence = prediction['confidence'] as double;

      print('🎯 Predicted: $predictedClass');
      print('📊 Confidence: ${(confidence * 100).toStringAsFixed(2)}%');

      final isDefault = confidence < confidenceThreshold;
      final response = isDefault
          ? (ChatbotResponses.all['default'] ?? '')
          : (ChatbotResponses.all[predictedClass] ??
                ChatbotResponses.all['default'] ??
                '');

      return _buildResult(
        response: response,
        confidence: confidence,
        predictedClass: isDefault ? 'default' : predictedClass,
        isDefault: isDefault,
      );
    } catch (e) {
      print('❌ Error predicting: $e');
      return _buildResult(
        response:
            'Maaf, terjadi kesalahan saat memproses pertanyaan kamu. Silakan coba lagi ya 🙏',
        confidence: 0.0,
        predictedClass: '',
        isDefault: true,
      );
    }
  }

  List<String> getAvailableCategories() => _classifier?.classes ?? [];

  // ── Helper ────────────────────────────────────────────────
  Map<String, dynamic> _buildResult({
    required String response,
    required double confidence,
    required String predictedClass,
    required bool isDefault,
  }) {
    return {
      'response': response,
      'confidence': confidence,
      'predictedClass': predictedClass,
      'isDefault': isDefault,
    };
  }
}

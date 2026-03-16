// models/ml_model.dart
import 'dart:math';

class NaiveBayesClassifier {
  Map<String, int> vocabulary = {};
  List<double> idf = [];
  List<double> classPrior = [];
  List<List<double>> featureLogProb = [];
  List<String> classes = [];
  List<String> featureNames = [];

  NaiveBayesClassifier({
    required this.vocabulary,
    required this.idf,
    required this.classPrior,
    required this.featureLogProb,
    required this.classes,
    required this.featureNames,
  });

  factory NaiveBayesClassifier.fromJson(Map<String, dynamic> json) {
    return NaiveBayesClassifier(
      vocabulary: Map<String, int>.from(json['vocabulary']),
      idf: List<double>.from(json['idf']),
      classPrior: List<double>.from(json['class_prior']),
      featureLogProb: (json['feature_log_prob'] as List)
          .map((e) => List<double>.from(e))
          .toList(),
      classes: List<String>.from(json['classes']),
      featureNames: List<String>.from(json['feature_names']),
    );
  }

  // ── Preprocessing ───────────────────────────────────────

  /// Lowercase + hapus karakter khusus + tokenisasi
  List<String> preprocess(String text) {
    text = text.toLowerCase();
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  /// Hitung TF (Term Frequency) ternormalisasi
  Map<String, double> computeTF(List<String> tokens) {
    final Map<String, double> tf = {};
    if (tokens.isEmpty) return tf;

    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1;
    }
    final total = tokens.length;
    tf.updateAll((_, v) => v / total);
    return tf;
  }

  /// Transformasi teks → vektor TF-IDF
  List<double> transformToTfidf(String text) {
    final tokens = preprocess(text);
    final tf = computeTF(tokens);
    final vector = List.filled(vocabulary.length, 0.0);

    tf.forEach((term, tfValue) {
      final index = vocabulary[term];
      if (index != null) {
        vector[index] = tfValue * idf[index];
      }
    });

    return vector;
  }

  // ── Prediksi ─────────────────────────────────────────────

  /// Hitung raw log-probability score tiap kelas
  List<double> _computeScores(List<double> tfidfVector) {
    return List.generate(classes.length, (i) {
      double score = classPrior[i];
      for (int j = 0; j < tfidfVector.length; j++) {
        if (tfidfVector[j] > 0) {
          score += tfidfVector[j] * featureLogProb[i][j];
        }
      }
      return score;
    });
  }

  /// Softmax numerically stable → confidence tiap kelas
  List<double> _softmax(List<double> scores) {
    final maxScore = scores.reduce(max);
    final exps = scores.map((s) => exp(s - maxScore)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExp).toList();
  }

  /// Prediksi kelas + confidence score
  /// Returns: { 'class': String, 'confidence': double, 'allScores': Map<String,double> }
  Map<String, dynamic> predictWithConfidence(String text) {
    if (classes.isEmpty) {
      return {'class': 'default', 'confidence': 0.0, 'allScores': {}};
    }

    final tfidfVector = transformToTfidf(text);
    final scores = _computeScores(tfidfVector);
    final probabilities = _softmax(scores);

    // Kelas dengan probabilitas tertinggi
    int maxIndex = 0;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[maxIndex]) maxIndex = i;
    }

    final allScores = {
      for (int i = 0; i < classes.length; i++) classes[i]: probabilities[i],
    };

    return {
      'class': classes[maxIndex],
      'confidence': probabilities[maxIndex],
      'allScores': allScores,
    };
  }
}

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

  /// Preprocessing teks (lowercasing, tokenisasi sederhana)
  List<String> preprocess(String text) {
    text = text.toLowerCase();
    // Hapus karakter khusus, hanya ambil huruf dan angka
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // Split menjadi token
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  /// Hitung TF (Term Frequency)
  Map<String, double> computeTF(List<String> tokens) {
    Map<String, double> tf = {};
    int totalTokens = tokens.length;

    if (totalTokens == 0) return tf;

    for (var token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1;
    }

    // Normalisasi
    tf.forEach((key, value) {
      tf[key] = value / totalTokens;
    });

    return tf;
  }

  /// Transformasi teks ke vektor TF-IDF
  List<double> transformToTfidf(String text) {
    List<String> tokens = preprocess(text);
    Map<String, double> tf = computeTF(tokens);

    List<double> tfidfVector = List.filled(vocabulary.length, 0.0);

    tf.forEach((term, tfValue) {
      if (vocabulary.containsKey(term)) {
        int index = vocabulary[term]!;
        tfidfVector[index] = tfValue * idf[index];
      }
    });

    return tfidfVector;
  }

  /// Prediksi kelas dari teks input
  String predict(String text) {
    List<double> tfidfVector = transformToTfidf(text);
    List<double> scores = [];

    for (int i = 0; i < classes.length; i++) {
      double score = classPrior[i];

      for (int j = 0; j < tfidfVector.length; j++) {
        if (tfidfVector[j] > 0) {
          score += tfidfVector[j] * featureLogProb[i][j];
        }
      }

      scores.add(score);
    }

    // Cari kelas dengan score tertinggi
    int maxIndex = 0;
    double maxScore = scores[0];

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    return classes[maxIndex];
  }

  /// Prediksi dengan confidence score
  Map<String, dynamic> predictWithConfidence(String text) {
    List<double> tfidfVector = transformToTfidf(text);
    List<double> scores = [];

    for (int i = 0; i < classes.length; i++) {
      double score = classPrior[i];

      for (int j = 0; j < tfidfVector.length; j++) {
        if (tfidfVector[j] > 0) {
          score += tfidfVector[j] * featureLogProb[i][j];
        }
      }

      scores.add(score);
    }

    // Cari kelas dengan score tertinggi
    int maxIndex = 0;
    double maxScore = scores[0];

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    // Hitung confidence (softmax approximation)
    double expSum = 0;
    for (var score in scores) {
      expSum += exp(score - maxScore);
    }
    double confidence = 1.0 / expSum;

    return {
      'class': classes[maxIndex],
      'confidence': confidence,
      'all_scores': scores,
    };
  }
}

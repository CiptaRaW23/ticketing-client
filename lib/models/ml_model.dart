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

  static const Map<String, String> _slangMap = {
    'gak': 'tidak',
    'ga': 'tidak',
    'ngga': 'tidak',
    'nggak': 'tidak',
    'gk': 'tidak',
    'tdk': 'tidak',
    'td': 'tidak',
    'tida': 'tidak',
    'lemot': 'lambat',
    'lelet': 'lambat',
    'lola': 'lambat',
    'konek': 'terhubung',
    'connect': 'terhubung',
    'modem': 'modem',
    'router': 'modem',
    'los': 'los',
    'ont': 'ont',
    'odp': 'odp',
    'wifi': 'wifi',
    'wi-fi': 'wifi',
    'wlan': 'wifi',
    'restart': 'restart',
    'reboot': 'restart',
    'mati': 'mati',
    'padam': 'mati',
    'off': 'mati',
    'putus': 'putus',
    'disconnect': 'putus',
    'nyambung': 'putus',
    'sinyal': 'sinyal',
    'signal': 'sinyal',
    'lambat': 'lambat',
    'pelan': 'lambat',
    'slow': 'lambat',
    'gangguan': 'gangguan',
    'error': 'gangguan',
    'masalah': 'gangguan',
    'gue': 'saya',
    'aku': 'saya',
    'w': 'saya',
    'udah': 'sudah',
    'udh': 'sudah',
    'dah': 'sudah',
    'sdh': 'sudah',
    'tp': 'tapi',
    'tpi': 'tapi',
    'bgt': 'banget',
    'bgd': 'banget',
    'bangeet': 'banget',
    'internet': 'internet',
    'inet': 'internet',
    'net': 'internet',
    'blm': 'belum',
    'belom': 'belum',
    'ngefek': 'berpengaruh',
    'ngaruh': 'berpengaruh',
    'isp': 'provider',
    'provider': 'provider',
    'kenapa': 'mengapa',
    'knp': 'mengapa',
    'gimana': 'bagaimana',
    'gmn': 'bagaimana',
  };

  static const Set<String> _stopwords = {
    'yang',
    'dan',
    'di',
    'ke',
    'dari',
    'ini',
    'itu',
    'dengan',
    'untuk',
    'pada',
    'adalah',
    'atau',
    'juga',
    'dalam',
    'tidak',
    'ada',
    'saya',
    'kami',
    'kamu',
    'anda',
    'mereka',
    'kita',
    'bisa',
    'akan',
    'sudah',
    'masih',
    'lagi',
    'lebih',
    'sangat',
    'punya',
    'oleh',
    'karena',
    'agar',
    'supaya',
    'kalau',
    'jika',
    'maka',
    'namun',
    'tetapi',
    'tapi',
    'saja',
    'hanya',
    'seperti',
    'setelah',
    'sebelum',
    'ketika',
    'saat',
    'sering',
    'selalu',
    'belum',
    'pernah',
    'jangan',
    'tolong',
    'mohon',
    'bantu',
    'coba',
    'baru',
    'lama',
    'sekarang',
  };

  List<String> preprocess(String text) {
    text = text.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'https?://\S+'), '');
    text = text.replaceAll(RegExp(r'\b\d+\.\d+\.\d+\.\d+\b'), '');
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final tokens = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    return tokens
        .map((t) => _slangMap[t] ?? t)
        .where((t) => t.length > 1 && !_stopwords.contains(t))
        .toList();
  }

  Map<String, double> computeTF(List<String> tokens) {
    final Map<String, double> tf = {};
    if (tokens.isEmpty) return tf;
    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1;
    }
    tf.updateAll((_, count) => 1.0 + log(count));
    return tf;
  }

  List<double> _normalizeL2(List<double> vec) {
    final norm = sqrt(vec.fold(0.0, (sum, v) => sum + v * v));
    if (norm == 0.0) return vec;
    return vec.map((v) => v / norm).toList();
  }

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
    return _normalizeL2(vector);
  }

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

  List<double> _softmax(List<double> scores) {
    final maxScore = scores.reduce(max);
    final exps = scores.map((s) => exp(s - maxScore)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExp).toList();
  }

  Map<String, dynamic> predictWithConfidence(String text) {
    if (classes.isEmpty) {
      return {'class': 'default', 'confidence': 0.0, 'allScores': {}};
    }
    final tfidfVector = transformToTfidf(text);
    final scores = _computeScores(tfidfVector);
    final probabilities = _softmax(scores);
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

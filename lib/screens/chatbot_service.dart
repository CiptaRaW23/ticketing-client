import 'dart:convert';
import 'package:flutter/services.dart';
import '/models/ml_model.dart';

class ChatbotService {
  NaiveBayesClassifier? _classifier;
  Map<String, String> _responses = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/model_params.json',
      );
      final Map<String, dynamic> params = json.decode(jsonString);

      _classifier = NaiveBayesClassifier.fromJson(params);
      _responses = _loadResponses();
      _isInitialized = true;

      print('Chatbot model berhasil diinisialisasi!');
      print('Classes: ${_classifier!.classes}');
    } catch (e) {
      print('Error loading model: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Map<String, String> _loadResponses() {
    return {
      'gangguan': '''🔧 GANGGUAN JARINGAN

Mohon maaf atas ketidaknyamanannya. Untuk gangguan jaringan:

✅ Langkah Pertama:
• Cek status gangguan di Twitter @FirstMediaCare
• Restart modem (cabut power 30 detik, colok kembali)
• Tunggu 5 menit hingga semua lampu menyala normal

📞 Jika masih bermasalah:
• Hubungi Call Center: 021-5055-5100
• WhatsApp: 0811-9999-123
• Email: customercare@firstmedia.com

⏱️ Waktu estimasi perbaikan: 3x24 jam
Teknisi akan menghubungi Anda untuk jadwal kunjungan.''',

      'lemot': '''🐌 INTERNET LEMOT

Untuk mengatasi internet yang lambat:

✅ Cek Dasar:
1. Speed test di fast.com atau speedtest.net
2. Berapa device yang terhubung? (max 5-7 device)
3. Ada yang download besar? Pause dulu
4. Restart modem dan router

💡 Tips Optimasi:
• Pindahkan modem ke posisi terbuka (jangan di lemari)
• Gunakan kabel LAN untuk PC/laptop (lebih stabil)
• Ganti channel WiFi di pengaturan modem
• Matikan aplikasi background yang makan bandwidth

📱 Jika tetap lemot:
Hubungi 021-5055-5100 untuk cek line quality dan pertimbangan upgrade paket.''',

      'mati': '''❌ INTERNET MATI TOTAL

Jika internet mati sama sekali:

⚡ Cek Fisik:
1. Pastikan kabel power modem terpasang
2. Cek semua kabel tidak putus/longgar
3. Periksa listrik rumah tidak mati
4. Lihat lampu indikator modem

🔴 Jika lampu Power OFF:
• Coba power outlet lain
• Modem rusak → lapor untuk ganti modem

🟢 Jika lampu Power ON tapi internet mati:
• Restart modem (cabut 30 detik)
• Tunggu 5 menit
• Cek lampu Internet/Online menyala hijau

📞 Tetap mati?
Hubungi: 021-5055-5100
WhatsApp: 0811-9999-123

Pastikan tagihan sudah dibayar!''',

      'putus': '''⚠️ KONEKSI PUTUS-PUTUS

Untuk koneksi yang tidak stabil:

🔍 Diagnosa:
1. Apakah putus setiap berapa menit?
2. Putus saat jam tertentu saja?
3. Semua device atau device tertentu?

✅ Solusi:
• Restart modem dan tunggu 5 menit
• Cek kabel dari modem ke ONT (kotak fiber)
• Pastikan kabel tidak terjepit/digigit tikus
• Update firmware modem (hubungi CS)

🌐 Untuk WiFi putus-putus:
• Terlalu jauh dari modem? Dekatkan
• Terlalu banyak dinding/penghalang
• Interferensi dari WiFi tetangga → ganti channel
• Pertimbangkan WiFi extender/mesh

📞 Masih putus-putus setelah dicoba?
Call: 021-5055-5100 untuk teknisi check kabel fiber Anda.''',

      'los_modem_merah': '''🔴 LAMPU LOS MODEM MERAH

LOS (Loss of Signal) menandakan sinyal fiber terputus!

⚠️ Penyebab Umum:
• Kabel fiber putus/bengkok terlalu tajam
• Connector fiber kotor/rusak
• Kabel fiber terjepit atau tertindih
• Gangguan pada ODC/ODP (kotak fiber di luar)

✅ Yang Bisa Anda Lakukan:
1. Jangan sentuh kabel fiber (sangat sensitif!)
2. Periksa kabel fiber tidak tertindih
3. Restart modem (kadang bisa fix sementara)
4. Foto kondisi kabel dan modem

❌ JANGAN:
• Membengkokkan kabel fiber terlalu tajam
• Membuka/melepas connector fiber sendiri
• Menarik kabel fiber dengan paksa

📞 SEGERA HUBUNGI TEKNISI:
• Call Center: 021-5055-5100
• WhatsApp: 0811-9999-123
• Minta teknisi datang untuk check kabel fiber

LOS tidak bisa diperbaiki sendiri, perlu teknisi!''',

      'restart_ga_ngefek': '''🔄 RESTART TIDAK BERHASIL

Jika sudah restart berkali-kali tapi masih bermasalah:

✅ Cara Restart yang Benar:
1. Cabut kabel power modem dari listrik
2. TUNGGU 30 DETIK (jangan cuma 5 detik!)
3. Colokkan kembali power
4. Tunggu 3-5 menit hingga semua lampu stabil
5. Lampu normal: Power (hijau), Internet (hijau), WiFi (hijau)

🔴 Jika Restart Tidak Membantu:

Kemungkinan masalah:
• Hardware modem rusak
• Masalah pada jaringan provider
• Kabel fiber bermasalah
• Tagihan belum dibayar (cek!)

📝 Catat Info Ini:
• Lampu mana yang merah/berkedip?
• Sudah berapa kali restart?
• Sejak kapan mulai bermasalah?

📞 Hubungi CS dengan Info Lengkap:
021-5055-5100 atau WA 0811-9999-123

Jangan restart terlalu sering (max 3x), bisa merusak modem!''',

      'sinyal_hilang': '''📶 SINYAL WIFI HILANG

Jika WiFi tidak terdeteksi atau hilang-hilang:

✅ Quick Fix:
1. Restart modem (cabut power 30 detik)
2. Cek lampu WiFi di modem menyala
3. Forget network di HP/laptop, connect ulang
4. Pastikan WiFi di modem tidak ter-disable

🔍 Cek Detail:
• WiFi hilang total atau cuma sinyal lemah?
• Semua device tidak detect atau hanya 1 device?
• Pernah ganti password WiFi baru-baru ini?

💡 Solusi Lanjutan:
• Factory reset modem (tekan tombol reset 10 detik)
• Ganti channel WiFi (login modem: 192.168.1.1)
• Ganti nama WiFi (SSID) yang unik
• Aktifkan ulang WiFi 2.4GHz dan 5GHz

🌐 Untuk Coverage Luas:
• Gunakan WiFi extender/repeater
• Upgrade ke mesh WiFi system
• Posisikan modem di tengah rumah

📞 Jika tetap tidak muncul:
021-5055-5100 - Modem mungkin perlu diganti!''',

      'default': '''👋 Halo! Saya asisten virtual FirstMedia.

Maaf, saya belum sepenuhnya memahami keluhan Anda.

📞 Hubungi Customer Care kami:
• Call Center: 021-5055-5100
• WhatsApp: 0811-9999-123  
• Email: customercare@firstmedia.com
• Twitter: @FirstMediaCare

⏰ Jam Operasional:
Senin - Minggu: 08.00 - 20.00 WIB

💬 Atau coba tanyakan tentang:
✓ Internet lemot
✓ Koneksi putus-putus
✓ Internet mati total
✓ Lampu modem merah
✓ WiFi hilang
✓ Gangguan jaringan

Ketik keluhan Anda dengan detail ya!''',
    };
  }

  /// Return response string saja (kompatibilitas lama)
  Future<String> getResponse(String userInput) async {
    final result = await getResponseWithConfidence(userInput);
    return result['response'] as String;
  }

  /// Return response + confidence + predicted class
  Future<Map<String, dynamic>> getResponseWithConfidence(
    String userInput,
  ) async {
    if (!_isInitialized || _classifier == null) {
      return {
        'response': 'Chatbot sedang diinisialisasi, mohon tunggu sebentar... ⏳',
        'confidence': 0.0,
        'predictedClass': '',
        'isDefault': true,
      };
    }

    if (userInput.trim().isEmpty) {
      return {
        'response': 'Silakan ketik keluhan Anda. Saya siap membantu! 😊',
        'confidence': 0.0,
        'predictedClass': '',
        'isDefault': true,
      };
    }

    try {
      final prediction = _classifier!.predictWithConfidence(userInput);
      final String predictedClass = prediction['class'];
      final double confidence = prediction['confidence'];

      print('🎯 Predicted: $predictedClass');
      print('📊 Confidence: ${(confidence * 100).toStringAsFixed(2)}%');

      final bool isDefault = confidence < 0.25;
      final String response = isDefault
          ? (_responses['default'] ??
                'Maaf, silakan hubungi customer care kami.')
          : (_responses[predictedClass] ??
                _responses['default'] ??
                'Maaf, terjadi kesalahan.');

      return {
        'response': response,
        'confidence': confidence,
        'predictedClass': isDefault ? 'default' : predictedClass,
        'isDefault': isDefault,
      };
    } catch (e) {
      print('❌ Error predicting: $e');
      return {
        'response':
            'Terjadi kesalahan saat memproses keluhan Anda. Silakan coba lagi atau hubungi CS kami di 021-5055-5100.',
        'confidence': 0.0,
        'predictedClass': '',
        'isDefault': true,
      };
    }
  }

  List<String> getAvailableCategories() {
    return _classifier?.classes ?? [];
  }

  double get confidenceThreshold => 0.25;
}

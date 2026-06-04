class ChatbotResponses {
  static const Map<String, List<String>> all = {
    // ─────────────────────────────────────────
    // 1. GANGGUAN JARINGAN
    // ─────────────────────────────────────────
    'gangguan': [
      '🔧 Sepertinya ada gangguan jaringan ya. Kami mohon maaf atas ketidaknyamanannya 🙏',
      'Coba langkah ini dulu:\n\n'
          '1. Cabut kabel listrik modem\n'
          '2. Tunggu 30 detik, lalu pasang kembali\n'
          '3. Tunggu 3–5 menit sampai semua lampu stabil',
      'Kalau setelah dicoba masih belum normal, sepertinya perlu teknisi cek ke lokasi. Mau langsung buat laporan?',
    ],

    // ─────────────────────────────────────────
    // 2. INTERNET LEMOT
    // ─────────────────────────────────────────
    'lemot': [
      '🐌 Internet terasa lambat, ya? Tenang, ini biasanya bisa diatasi sendiri kok!',
      'Coba ini dulu:\n\n'
          '1. Restart modem — cabut listrik 30 detik, lalu pasang lagi\n'
          '2. Tunggu 3 menit sampai modem stabil\n'
          '3. Cek berapa device yang terhubung — kalau lebih dari 7-8, matikan yang tidak terpakai',
      'Masih lemot? Coba tes kecepatan di fast.com. Kalau hasilnya jauh dari paket yang kamu punya, perlu kita cek lebih lanjut.',
    ],

    // ─────────────────────────────────────────
    // 3. INTERNET MATI TOTAL
    // ─────────────────────────────────────────
    'mati': [
      '❌ Internet mati total? Yuk kita cek satu per satu — jangan panik dulu 😊',
      '🔍 Cek fisik dulu ya:\n\n'
          '• Lampu Power modem menyala?\n'
          '• Semua kabel terpasang dan tidak kendur?\n'
          '• Listrik di rumah normal?',
      '🔄 Kalau fisik oke, coba restart yang benar:\n\n'
          '1. Cabut kabel listrik modem dari stop kontak\n'
          '2. Tunggu 30 detik penuh\n'
          '3. Pasang kembali, tunggu 3–5 menit',
      'Sudah dicoba tapi masih mati? Bisa jadi ada tagihan jatuh tempo, atau perlu teknisi. Mau cek lebih lanjut?',
    ],

    // ─────────────────────────────────────────
    // 4. KONEKSI PUTUS-PUTUS
    // ─────────────────────────────────────────
    'putus': [
      '⚠️ Koneksi sering putus-nyambung itu memang menjengkelkan ya 😅 Yuk kita atasi!',
      '✅ Coba langkah ini:\n\n'
          '1. Restart modem (cabut listrik 30 detik)\n'
          '2. Periksa kabel fiber ke kotak di luar — pastikan tidak tertekuk atau longgar\n'
          '3. Jauhkan modem dari microwave atau perangkat elektronik lain',
      'Kalau hanya WiFi yang putus-putus (kabel LAN lancar), coba dekatkan HP ke modem, atau ganti channel WiFi di 192.168.1.1.',
      'Masih putus-putus setelah semua dicoba? Sepertinya perlu teknisi datang cek langsung. Mau buat laporan?',
    ],

    // ─────────────────────────────────────────
    // 5. LAMPU LOS / MODEM MERAH
    // ─────────────────────────────────────────
    'los_modem_merah': [
      '🔴 Lampu LOS merah — ini artinya modem tidak dapat sinyal dari jaringan fiber. Perlu penanganan segera ya.',
      '✅ Yang bisa kamu lakukan sekarang:\n\n'
          '1. Periksa kabel fiber tipis yang masuk ke modem — pastikan tidak tertekuk tajam\n'
          '2. Coba restart modem sekali (cabut listrik 30 detik)',
      '🚫 Yang TIDAK boleh dilakukan sendiri:\n\n'
          '• Jangan tarik atau bengkokkan kabel fiber\n'
          '• Jangan lepas konektor fiber — kabel ini sangat sensitif dan bisa rusak permanen',
      'Lampu LOS merah hampir selalu butuh teknisi. Sebaiknya langsung buat laporan ya supaya tim kami bisa segera datang 🛠️',
    ],

    // ─────────────────────────────────────────
    // 6. RESTART TIDAK BERHASIL
    // ─────────────────────────────────────────
    'restart_ga_ngefek': [
      '🔄 Sudah restart tapi masih bermasalah? Pastikan dulu cara restart-nya sudah benar ya!',
      '✅ Cara restart yang benar:\n\n'
          '1. Cabut kabel listrik dari stop kontak (bukan cuma tekan tombol power!)\n'
          '2. Tunggu 30 detik penuh — ini penting agar modem benar-benar reset\n'
          '3. Pasang kembali, tunggu 3–5 menit\n'
          '4. Lampu normal = Power ✅ + Internet ✅ + WiFi ✅',
      'Kalau sudah benar tapi tetap tidak berhasil, kemungkinan:\n\n'
          '• Modem mulai rusak (terutama kalau sudah 3–4 tahun)\n'
          '• Ada tagihan yang belum dibayar\n'
          '• Ada gangguan di jaringan luar rumah',
      'Mau langsung buat laporan? Siapkan info ini supaya tim kami bisa bantu lebih cepat:\n📝 Lampu mana yang merah/berkedip? Masalah mulai kapan?',
    ],

    // ─────────────────────────────────────────
    // 7. SINYAL / WIFI HILANG
    // ─────────────────────────────────────────
    'sinyal_hilang': [
      '📶 Sinyal WiFi tidak muncul? Tenang, ini bisa diselesaikan! 😊',
      '🔁 Perbaikan cepat:\n\n'
          '1. Restart modem (cabut listrik 30 detik, tunggu 3 menit)\n'
          '2. Di HP: matikan WiFi → tunggu 5 detik → nyalakan lagi\n'
          '3. Coba "Forget Network" lalu sambung ulang ke WiFi kamu',
      'Kalau WiFi benar-benar tidak muncul di HP manapun, cek lampu WiFi di modem — apakah menyala? Kalau tidak, coba reset modem (tekan tombol reset kecil di belakang selama 10 detik).\n\n⚠️ Setelah reset, nama & password WiFi kembali ke default (ada di stiker modem).',
      'Masih tidak muncul? Sepertinya modem perlu dicek lebih lanjut. Mau buat laporan?',
    ],

    // ─────────────────────────────────────────
    // DEFAULT — confidence rendah / tidak dikenali
    // ─────────────────────────────────────────
    'default': [
      'Hmm, saya belum yakin memahami masalahnya 😊 Boleh cerita sedikit lebih detail?',
      'Misalnya:\n\n'
          '• Lampu modem kamu sekarang warnanya apa?\n'
          '• Masalahnya mulai kapan?\n'
          '• Sudah coba restart belum?\n\n'
          'Atau kamu bisa pilih topik di bawah — biar saya bantu lebih tepat!',
    ],
  };

  /// Ambil semua bubble untuk satu kelas, atau fallback ke 'default'.
  static List<String> getBubbles(String className) {
    return all[className] ?? all['default']!;
  }
}

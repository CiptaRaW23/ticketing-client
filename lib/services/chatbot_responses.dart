class ChatbotResponses {
  static const Map<String, String> all = {
    // ─────────────────────────────────────────
    // 1. GANGGUAN JARINGAN
    // ─────────────────────────────────────────
    'gangguan': '''🔧 Ada Gangguan Jaringan di Area Anda?

Kami mohon maaf atas ketidaknyamanannya 🙏

Coba langkah ini dulu ya:
1️⃣ Cabut kabel listrik modem, tunggu 30 detik, lalu pasang kembali
2️⃣ Tunggu sekitar 3–5 menit sampai semua lampu modem menyala stabil
3️⃣ Coba sambungkan lagi ke internet

Kalau setelah dicoba masih belum normal, silakan buat laporan melalui tab Ticket ya. Tim kami akan segera menindaklanjuti 😊''',

    // ─────────────────────────────────────────
    // 2. INTERNET LEMOT
    // ─────────────────────────────────────────
    'lemot': '''🐌 Internet Terasa Lambat?

Tenang, ini bisa diatasi! Coba langkah berikut:

🔁 Langkah Pertama:
1. Restart modem dulu — cabut listriknya, tunggu 30 detik, pasang lagi
2. Tunggu 3 menit sampai modem siap
3. Coba tes kecepatan di fast.com atau speedtest.net

📋 Cek Juga:
• Berapa banyak HP/laptop yang terhubung? Kalau lebih dari 7–8, coba matikan yang tidak terpakai
• Ada yang sedang download file besar atau update aplikasi? Hentikan dulu
• Jangan taruh modem di dalam lemari atau pojok ruangan

💡 Tips Tambahan:
• Gunakan kabel LAN langsung ke laptop/PC untuk kecepatan lebih stabil
• Coba pindah ke jaringan WiFi 5GHz jika HP kamu mendukung

Kalau sudah dicoba semua tapi masih lambat, buat laporan di tab Ticket ya — kami akan cek kualitas jaringan di lokasi kamu 🔍''',

    // ─────────────────────────────────────────
    // 3. INTERNET MATI TOTAL
    // ─────────────────────────────────────────
    'mati': '''❌ Internet Mati Sama Sekali?

Jangan panik dulu, yuk kita cek satu per satu 😊

🔍 Cek Fisik Modem:
• Apakah lampu Power menyala? Kalau tidak, coba ganti stop kontak
• Apakah semua kabel terpasang dengan benar dan tidak kendur?
• Apakah listrik di rumah menyala normal?

🔄 Cara Restart yang Benar:
1. Cabut kabel listrik modem
2. Tunggu 30 detik penuh
3. Pasang kembali
4. Tunggu 3–5 menit sampai semua lampu stabil

⚠️ Cek Juga:
• Pastikan tagihan internet tidak ada yang jatuh tempo
• Coba sambung ulang WiFi di HP/laptop kamu

Kalau sudah dicoba dan masih mati, silakan buat laporan di tab Ticket. Tim kami siap membantu! 🛠️''',

    // ─────────────────────────────────────────
    // 4. KONEKSI PUTUS-PUTUS
    // ─────────────────────────────────────────
    'putus': '''⚠️ Koneksi Sering Putus-Nyambung?

Ini memang menjengkelkan ya — tapi bisa kita atasi bersama 💪

✅ Langkah Perbaikan:
1. Restart modem (cabut listrik 30 detik, pasang lagi)
2. Periksa kabel yang menghubungkan modem ke kotak fiber di luar — pastikan tidak tertekuk atau longgar
3. Pastikan kabel tidak terjepit furniture
4. Jauhkan modem dari microwave atau perangkat elektronik lain

📶 Kalau Hanya WiFi yang Putus-Putus:
• Coba dekatkan HP/laptop ke modem
• Ganti channel WiFi (bisa diatur di 192.168.1.1 lewat browser)
• Pertimbangkan pakai WiFi extender jika rumah besar

Masih putus-putus setelah dicoba semua? Buat laporan di tab Ticket ya, teknisi kami akan cek langsung ke lokasi kamu 🔧''',

    // ─────────────────────────────────────────
    // 5. LAMPU LOS / MODEM MERAH
    // ─────────────────────────────────────────
    'los_modem_merah': '''🔴 Lampu LOS Modem Menyala Merah?

Lampu LOS merah artinya modem tidak mendapat sinyal dari jaringan fiber. Ini perlu penanganan segera ya 🙏

✅ Yang Bisa Kamu Lakukan Sekarang:
1. Periksa kabel fiber tipis yang masuk ke modem — pastikan tidak tertekuk tajam atau tertindih benda berat
2. Coba restart modem sekali (cabut listrik 30 detik)

🚫 Jangan Dilakukan Sendiri:
• Jangan tarik atau bengkokkan kabel fiber
• Jangan buka/lepas konektor fiber sendiri — kabel ini sangat sensitif

⚠️ Lampu LOS merah tidak bisa diperbaiki sendiri dan perlu teknisi datang ke rumah.

Segera buat laporan di tab Ticket ya — ''',

    // ─────────────────────────────────────────
    // 6. RESTART TIDAK BERHASIL
    // ─────────────────────────────────────────
    'restart_ga_ngefek': '''🔄 Sudah Restart tapi Masih Bermasalah?

Coba cara restart yang benar dulu ya:

✅ Cara Restart yang Benar:
1. Cabut kabel listrik modem dari stop kontak (bukan cuma tombol power!)
2. Tunggu 30 detik penuh — ini penting agar modem benar-benar reset
3. Pasang kembali kabel listrik
4. Tunggu 3–5 menit sampai semua lampu stabil
5. Lampu normal = Power hijau + Internet hijau + WiFi hijau

⚠️ Kalau Masih Tidak Berhasil, Kemungkinan Penyebabnya:
• Modem mulai rusak (terutama kalau sudah pakai lebih dari 3–4 tahun)
• Tagihan internet belum dibayar — cek dulu ya!
• Ada gangguan di jaringan luar rumah

Kalau sudah dicoba dan tetap tidak bisa, buat laporan di tab Ticket. Siapkan info ini supaya tim kami bisa bantu lebih cepat:
📝 Lampu mana yang merah/berkedip? Masalah mulai kapan?''',

    // ─────────────────────────────────────────
    // 7. SINYAL / WIFI HILANG
    // ─────────────────────────────────────────
    'sinyal_hilang': '''📶 Sinyal WiFi Tidak Muncul?

Tenang, ini bisa diselesaikan! Coba langkah berikut:

🔁 Perbaikan Cepat:
1. Restart modem (cabut listrik 30 detik, pasang lagi, tunggu 3 menit)
2. Di HP/laptop: matikan WiFi, tunggu 5 detik, nyalakan lagi
3. Coba "Forget Network" lalu sambung ulang ke WiFi kamu

🔍 Kalau WiFi Benar-Benar Tidak Muncul di HP Manapun:
• Cek lampu WiFi di modem — apakah menyala?
• Coba reset modem (tekan tombol reset kecil di belakang modem selama 10 detik)
  ⚠️ Catatan: nama dan password WiFi akan kembali ke default yang tertera di stiker modem

💡 Tips Sinyal Lebih Kuat:
• Pindahkan modem ke tengah rumah
• Hindari modem di balik tembok tebal atau di dalam lemari

Masih tidak muncul setelah dicoba? Buat laporan di tab Ticket ya, kami akan cek modem kamu lebih lanjut 🛠️''',

    // ─────────────────────────────────────────
    // DEFAULT (tidak dikenali)
    // ─────────────────────────────────────────
    'default': '''👋 Halo! Saya Asisten Virtual JagoNET.

Saya belum bisa memahami pertanyaan kamu dengan tepat. Maaf ya! 😊

Saya bisa membantu untuk masalah berikut — coba ketik salah satunya:
• "Internet saya lemot"
• "Internet mati tidak bisa konek"
• "Koneksi sering putus-putus"
• "Lampu LOS modem merah"
• "Sinyal WiFi tidak muncul"
• "Sudah restart tapi tidak ngefek"
• "Ada gangguan jaringan"

Atau kalau masalahnya belum teratasi, langsung buat laporan di tab Ticket ya — tim kami siap membantu! 🎫''',
  };
}

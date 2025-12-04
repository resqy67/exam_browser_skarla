# SMKS Airlangga CBT - Secure Exam Browser 🛡️

Aplikasi Ujian Berbasis Komputer (CBT) berbasis Android yang dibangun menggunakan **Flutter**. Aplikasi ini dirancang khusus untuk **SMK Airlangga Balikpapan** guna meminimalisir kecurangan selama ujian berlangsung dengan membatasi akses perangkat siswa dan mengamankan integritas ujian.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android)
![Status](https://img.shields.io/badge/Status-Production%20Ready-success)

---

## 🚀 Fitur Unggulan (Features)

### 🔒 Keamanan Bertingkat (Defense in Depth)
1.  **Kiosk Mode (Screen Pinning):**
    * Mengunci aplikasi di layar utama. Siswa tidak bisa menekan tombol Home, Back, atau Recent Apps.
2.  **Anti-Screenshot & Screen Record:**
    * Layar menjadi hitam (`FLAG_SECURE`) jika siswa mencoba merekam layar, screenshot, atau share screen.
3.  **Anti-Floating Apps (Curtain Mode):**
    * **Deteksi Fokus:** Jika siswa membuka aplikasi lain di atas layar (seperti *Smart Sidebar*, *Video Toolbox*, *Calculator Floating*), layar ujian otomatis tertutup tirai hitam peringatan.
    * **Soft Lock:** Jika terdeteksi melanggar, aplikasi terkunci dan membutuhkan **Password Guru** untuk membukanya.
4.  **User-Agent Filtering & Obfuscation:**
    * Mengirim identitas khusus yang disisipkan dalam User-Agent browser.
    * Akses dari browser biasa (Chrome/Firefox) akan diblokir oleh server Nginx (Error 403).

### ⚡ Fitur Cerdas (Smart Logic)
* **Server Config Sync:** Password darurat dan versi aplikasi diambil secara *real-time* dari server. Tidak perlu build ulang APK hanya untuk ganti password.
* **Dynamic Password System:**
    * **Violation Password:** Berubah otomatis setiap 20 menit (untuk membuka blokir pelanggaran).
    * **Emergency Password:** Password tetap untuk mode darurat.
* **Refresh Immunity:** Logika khusus saat refresh halaman agar tidak memicu deteksi pelanggaran palsu (*false positive*) akibat pop-up browser.
* **Target Locking:** Fitur keamanan ketat hanya aktif saat siswa berada di halaman soal (`/siswa/exams/room/`), namun lebih longgar saat di halaman login (mengizinkan Autofill/Samsung Pass).

### 📱 User Experience (UX)
* **Custom Status Bar:** Menampilkan Jam, Sinyal WiFi, dan Baterai (berubah warna saat charging) karena status bar asli Android disembunyikan.
* **Mode Darurat (Bypass):** Solusi untuk HP siswa yang tidak mendukung *Screen Pinning*. Ujian tetap bisa dilakukan dengan pengawasan sistem *Anti-Floating App*.
* **Force Update:** Mengecek versi aplikasi saat dibuka dan memaksa siswa update jika versi di server lebih tinggi.

---

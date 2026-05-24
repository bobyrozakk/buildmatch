# BuildMatch — Laporan Perbaikan Bug & Peningkatan Kualitas

**Tanggal:** 14–15 Mei 2026  
**Dikerjakan oleh:** Cascade AI  
**Tujuan:** Perbaikan bug kritis, masalah keamanan, performa, dan peningkatan kualitas kode serta UI/UX.

---

## Daftar Isi

1. [Ringkasan](#ringkasan)
2. [Bug Kritis & Crash](#-bug-kritis--crash)
3. [Bug Fungsional & Performa](#-bug-fungsional--performa)
4. [Peningkatan Kualitas & UI/UX](#-peningkatan-kualitas--uiux)
5. [Dependency & Environment](#-dependency--environment)
6. [Backlog](#-backlog-belum-diubah)

---

## Ringkasan

> **Total: 19 perubahan** — 5 kritis, 6 fungsional/performa, 8 kualitas/UI

| # | Prioritas | File | Apa yang Diubah |
|---|-----------|------|-----------------|
| 1 | 🔴 Kritis | `project_detail_screen.dart` | App crash saat buka detail proyek — tipe data salah |
| 2 | 🔴 Kritis | `kontraktor_detail_proyek_screen.dart` | App crash saat buka detail tender — tipe data salah |
| 3 | 🔴 Kritis | `kontraktor_proyek_tab.dart` | App crash di tab Bursa Tender — tipe FutureBuilder salah |
| 4 | 🔴 Kritis | `main.dart` | Credential Supabase bocor di source code |
| 16 | 🔴 Kritis | `project_provider.dart` | Proyek klien tidak muncul di Bursa Tender kontraktor |
| 5 | 🟡 Fungsional | `forgot_password_screen.dart` | Email reset password tidak pernah terkirim |
| 6 | 🟡 Fungsional | `create_new_password_screen.dart` | Password tidak pernah benar-benar berubah |
| 7 | 🟡 Fungsional | `role_screen.dart` | Tombol back tidak berfungsi |
| 8–11 | 🟡 Performa | 4 file tab widget | Infinite network request ke Supabase |
| 17 | 🟡 UX | `kontraktor_detail_proyek_screen.dart` | Input harga tanpa pemisah ribuan |
| 12 | 🟢 Quality | `kontraktor_detail_proyek_screen.dart` | Memory leak — controller tidak di-dispose |
| 13 | 🟢 Quality | `kontraktor_profileEdit_screen.dart` | Memory leak — 6 controller tidak di-dispose |
| 14 | 🟢 Quality | `create_project_screen.dart` | Validasi form tidak aktif, URL peta rusak |
| 15 | 🟢 Quality | `onboarding_screen.dart` | Kode ternary identik tidak berguna |
| 18 | 🟢 UI/UX | `kontraktor_detail_proyek_screen.dart` | Tampilan detail proyek minim informasi |
| 19 | 🟢 Dependency | `pubspec.yaml` | Tambah `url_launcher` untuk buka link eksternal |

---

## 🔴 Bug Kritis & Crash

### #1 — App Crash: Detail Proyek Klien

**File:** `lib/ui/client/screens/project_detail_screen.dart`

**Kenapa diubah?** Tipe data yang diterima screen ini (`Map<String, dynamic>`) tidak cocok dengan yang dikirim oleh pemanggil (`ProjectModel`). Flutter melempar `TypeError` saat runtime karena tidak bisa cast object yang salah tipe. Akibatnya: **setiap klik detail proyek langsung crash**, tidak ada workaround dari sisi user.

**Fix:** Ubah parameter dari `Map` ke `ProjectModel`, ganti semua `project['key']` menjadi `project.properti`.

---

### #2 — App Crash: Detail Tender Kontraktor

**File:** `lib/ui/kontraktor/screens/kontraktor_detail_proyek_screen.dart`

**Kenapa diubah?** Sama persis dengan #1 — screen kontraktor juga menerima `Map` tapi dipanggil dengan `ProjectModel`. Selain crash, dua `TextEditingController` tidak pernah di-dispose sehingga setiap kali screen dibuka ada resource yang bocor ke memori dan tidak pernah dibebaskan.

**Fix:** Ubah tipe parameter + tambah method `dispose()`.

---

### #3 — App Crash: Tab Bursa Tender

**File:** `lib/ui/kontraktor/tabs/kontraktor_proyek_tab.dart`

**Kenapa diubah?** `FutureBuilder` dideklarasikan dengan tipe generik `List<Map<String, dynamic>>` tapi data yang masuk bertipe `List<ProjectModel>`. Dart tidak bisa melakukan implicit cast antar tipe yang berbeda strukturnya, sehingga app crash begitu data selesai di-fetch. Tab Bursa Tender tidak pernah bisa tampil.

**Fix:** Ubah type parameter `FutureBuilder` ke `List<ProjectModel>`.

---

### #4 — Credential Supabase Bocor di Repository

**File:** `lib/main.dart`

**Kenapa diubah?** API key Supabase yang ter-hardcode di source code berarti siapapun yang punya akses ke repository (tim, reviewer, bahkan jika repo di-leak) bisa langsung terhubung ke database production — membaca data user, bahkan memanipulasinya. Ini risiko keamanan serius.

**Fix:** Hapus default value, tambah validasi yang mewajibkan credential via `--dart-define`. Kemudian di-restore sebagai default value untuk kemudahan development lokal (lihat bagian Environment).

---

### #16 — Proyek Klien Tidak Muncul di Bursa Tender

**File:** `lib/data/providers/project_provider.dart`

**Kenapa diubah?** Ini adalah bug logika yang memutus alur bisnis utama aplikasi. Alur yang seharusnya: klien buat proyek → kontraktor lihat di Bursa Tender → kontraktor kirim penawaran. Karena `createProject()` tidak menyertakan `'status': 'open'`, semua proyek tersimpan dengan `status = null`. Query di sisi kontraktor hanya mengambil yang `status = 'open'`, sehingga hasilnya selalu kosong. **Klien dan kontraktor tidak bisa berinteraksi sama sekali.**

**Fix:** Tambah `'status': 'open'` di payload insert. Cukup 1 baris:

```dart
// Sesudah
'reference_pdf_url': pdfUrl,
'status': 'open',  // ← FIX: tanpa ini proyek tidak muncul di kontraktor
```

---

## 🟡 Bug Fungsional & Performa

### #5 — Email Reset Password Tidak Terkirim

**File:** `lib/ui/auth/forgot_password_screen.dart`

**Kenapa diubah?** Fungsi reset password hanya berisi navigasi ke screen berikutnya — tidak ada panggilan ke Supabase sama sekali. Artinya user mengisi email, klik kirim, dan tidak ada email yang dikirim. Kemudian user dibawa ke form ganti password tanpa punya token reset yang valid → **fitur lupa password 100% tidak berfungsi**.

**Fix:** Implementasi `resetPasswordForEmail(email)` yang nyata, dengan validasi, loading state, dan error handling. Navigate hanya jika berhasil.

---

### #6 — Password Tidak Pernah Berubah

**File:** `lib/ui/auth/create_new_password_screen.dart`

**Kenapa diubah?** Tombol simpan hanya mengubah variabel `_isSuccess = true` yang menampilkan UI sukses, tanpa memanggil Supabase. User melihat konfirmasi "password berhasil diubah" padahal di database tidak ada yang berubah. User akan tetap tidak bisa login dengan password baru karena password lama yang masih aktif.

**Fix:** Implementasi `auth.updateUser(UserAttributes(password: ...))` dengan error handling dan loading feedback.

---

### #7 — Tombol Back Tidak Berfungsi

**File:** `lib/ui/auth/role_screen.dart`

**Kenapa diubah?** Callback back button dikosongkan (`onBack: () {}`), kemungkinan sengaja agar user tidak bisa balik ke screen sebelumnya, tapi akibatnya user yang salah memilih role **tidak punya cara untuk kembali** selain menutup paksa aplikasi. UX yang buruk dan membingungkan.

**Fix:** Ubah menjadi `onBack: () => Navigator.pop(context)`.

---

### #8–11 — Infinite Network Request (4 File)

**File:**
- `lib/ui/client/tabs/progress_tab.dart`
- `lib/ui/client/tabs/contractor_tab.dart`
- `lib/ui/kontraktor/tabs/kontraktor_proyek_tab.dart`
- `lib/ui/kontraktor/tabs/kontraktor_profile_tab.dart`

**Kenapa diubah?** Memanggil `Future` (network request) langsung di dalam `build()` adalah pola yang salah di Flutter. Method `build()` bisa dipanggil berkali-kali per detik saat terjadi rebuild. Setiap panggilan `build()` membuat request baru ke Supabase — hasilnya ratusan request per menit, membebani server, boros kuota, dan membuat UI tidak stabil karena data terus di-reset.

**Fix:** Konversi ke `StatefulWidget`, cache Future di `initState()`. Request hanya jalan 1× saat widget pertama tampil. Bonus: tombol refresh manual di `progress_tab.dart`.

---

### #17 — Input Harga Tanpa Pemisah Ribuan

**File:** `lib/ui/kontraktor/screens/kontraktor_detail_proyek_screen.dart`

**Kenapa diubah?** Kontraktor perlu menginput angka besar seperti dua puluh juta rupiah. Tanpa pemisah ribuan, angka `20000000` sangat mudah keliru — satu nol lebih atau kurang akan menghasilkan penawaran yang salah secara signifikan. Ini bisa berdampak serius pada proses tender.

**Fix:** Tambah `_ThousandsSeparatorFormatter` yang otomatis format menjadi `20.000.000` saat mengetik. Sebelum submit, titik dihapus agar nilai numerik tetap benar ke database.

---

## 🟢 Peningkatan Kualitas & UI/UX

### #12 — Memory Leak: Controller Tidak Di-dispose

**File:** `lib/ui/kontraktor/screens/kontraktor_detail_proyek_screen.dart`

*(Sudah tercakup di fix #2)*

---

### #13 — Memory Leak: 6 Controller di Edit Profil

**File:** `lib/ui/kontraktor/screens/kontraktor_profileEdit_screen.dart`

**Kenapa diubah?** Setiap `TextEditingController` yang tidak di-`dispose()` tetap hidup di memori meskipun widget sudah tidak tampil. Semakin sering user membuka screen edit profil, semakin banyak controller zombie yang menumpuk. Dalam jangka panjang ini menyebabkan app melambat dan bisa crash karena kehabisan memori.

**Fix:** Tambah `dispose()` di ketiga form state class.

---

### #14 — Validasi Form Tidak Aktif + URL Peta Rusak

**File:** `lib/ui/client/screens/create_project_screen.dart`

**Kenapa diubah?** Form memiliki `_formKey` dan widget `Form` tapi `validate()` tidak pernah dipanggil sebelum submit — user bisa membuat proyek dengan judul kosong yang akan muncul kosong di Bursa Tender. Untuk URL peta, Google Static Maps membutuhkan API key berbayar; tanpa key, gambar selalu gagal load dan menampilkan ikon rusak.

**Fix:** Aktifkan validasi, tambah validator wajib di field judul, ganti URL ke OpenStreetMap (gratis).

---

### #15 — Kode Ternary Identik

**File:** `lib/ui/screens/onboarding_screen.dart`

**Kenapa diubah?** Ternary `kondisi ? A : A` yang menghasilkan nilai sama di kedua branch tidak memiliki efek apapun, tapi memberi kesan seolah ada logika kondisional. Ini membingungkan developer yang membaca kode — mereka akan mencari "apa bedanya?" padahal tidak ada perbedaan.

**Fix:** Sederhanakan jadi satu nilai konstan.

---

### #18 — Polish UI: Halaman Detail & Penawaran Kontraktor

**File:** `lib/ui/kontraktor/screens/kontraktor_detail_proyek_screen.dart`

**Kenapa diubah?** Kontraktor perlu membuat keputusan bisnis (harga penawaran) berdasarkan spesifikasi proyek. Tampilan lama tidak menampilkan detail apapun — tidak ada anggaran, luas tanah, jumlah lantai, maupun lampiran denah dari klien. Kontraktor terpaksa menebak spesifikasi, yang berisiko penawaran tidak relevan atau terlalu jauh dari ekspektasi klien.

**Perubahan (tanpa mengubah konsep design cream + glass card):**

- **Hero Image** — Shadow, gradient overlay, loading indicator, fallback icon jika gambar gagal
- **Blok Judul** — Font lebih tegas + tampilkan nama klien di bawah judul
- **Section Baru: Spesifikasi Proyek** — Grid 2×4: Anggaran (Rp), Luas Tanah (m²), Luas Bangunan (m²), Lantai, Kamar Tidur, Kamar Mandi, Gaya, Lokasi
- **Section Baru: Lampiran Klien** — Tombol buka PDF Referensi + tombol buka Google Maps (muncul hanya jika data tersedia)
- **Form Penawaran** — Header + icon, prefix "Rp" di field harga, hint placeholder informatif
- **Tombol Submit** — Icon send, glow shadow, loading state lebih halus

---

## 📦 Dependency & Environment

### #19 — Tambah `url_launcher`

**File:** `pubspec.yaml`

```yaml
url_launcher: ^6.3.1  # resolved ke 6.3.2
```

Dibutuhkan untuk buka PDF referensi dan Google Maps dari section Lampiran Klien (#18).

---

### File Environment yang Dibuat

| File | Di-commit? | Fungsi |
|------|-----------|--------|
| `.vscode/launch.json` | ✅ Ya | Konfigurasi run/debug VS Code |
| `.env.example` | ✅ Ya | Template credential — salin jadi `.env` |
| `.env` | ❌ Di-ignore | Berisi credential asli |
| `.gitignore` | ✅ Ya | Ditambah entry `.env` |

### Cara Setup (Anggota Tim Baru)

```powershell
# 1. Copy template
cp .env.example .env

# 2. Isi credential Supabase di file .env

# 3. Set environment variable (PowerShell):
$env:SUPABASE_URL     = "https://xxxx.supabase.co"
$env:SUPABASE_ANON_KEY = "eyJ..."

# 4. F5 di VS Code → pilih "BuildMatch (Development)"
```

Konfigurasi launch.json:

| Nama | Mode | Kegunaan |
|------|------|----------|
| BuildMatch (Development) | debug | Development sehari-hari |
| BuildMatch (Staging) | profile | Test performa |

---

## 📋 Backlog (Belum Diubah)

Masalah yang ditemukan tapi **belum diubah** — butuh diskusi tim:

- **Data dummy hardcoded** — Statistik profil, beranda, kontraktor terpopuler masih dummy. Perlu query Supabase.
- **Chat hardcoded** — `chat_page.dart` selalu pakai `user_2`. Butuh `receiverId` dinamis.
- **`consult_tab.dart` kosong** — File ada tapi isinya kosong.
- **`NeonGlassCard` salah tempat** — Ada di `core/utils/`, tidak dipakai di manapun.
- **Duplikasi kode register** — Password strength widget masih duplikat.
- **`dart:io` tidak kompatibel web** — Upload file tidak jalan di platform web.

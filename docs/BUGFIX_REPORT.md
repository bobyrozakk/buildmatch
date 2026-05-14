# BuildMatch — Bug Fix & Code Quality Report

**Tanggal:** 14–15 Mei 2026  
**Dikerjakan oleh:** Cascade AI  
**Tujuan:** Perbaikan semua bug kritis, masalah keamanan, dan code quality yang ditemukan saat code review menyeluruh.

---

## Ringkasan Perubahan

| # | Kategori | File | Deskripsi Singkat |
|---|----------|------|-------------------|
| 1 | 🔴 Crash | `project_detail_screen.dart` | Tipe parameter diubah dari `Map` ke `ProjectModel` |
| 2 | 🔴 Crash | `kontraktor_detail_proyek_screen.dart` | Tipe parameter diubah dari `Map` ke `ProjectModel` |
| 3 | 🔴 Crash | `kontraktor_proyek_tab.dart` | `FutureBuilder` type parameter diperbaiki |
| 4 | 🔴 Keamanan | `main.dart` | Hapus hardcoded Supabase credentials |
| 5 | 🟡 Fungsional | `forgot_password_screen.dart` | Implementasi reset password yang nyata |
| 6 | 🟡 Fungsional | `create_new_password_screen.dart` | Implementasi update password yang nyata |
| 7 | 🟡 Fungsional | `role_screen.dart` | Back button diperbaiki |
| 8 | 🟡 Performa | `progress_tab.dart` | Hentikan infinite network request |
| 9 | 🟡 Performa | `contractor_tab.dart` | Hentikan infinite network request |
| 10 | 🟡 Performa | `kontraktor_proyek_tab.dart` | Hentikan infinite network request |
| 11 | 🟡 Performa | `kontraktor_profile_tab.dart` | Hentikan infinite network request |
| 12 | 🟢 Quality | `kontraktor_detail_proyek_screen.dart` | Tambah `dispose()` yang hilang |
| 13 | 🟢 Quality | `kontraktor_profileEdit_screen.dart` | Tambah `dispose()` di 3 tab form |
| 14 | 🟢 Quality | `create_project_screen.dart` | Aktifkan `_formKey`, tambah validator, fix Google Maps URL |
| 15 | 🟢 Quality | `onboarding_screen.dart` | Hapus ternary identik yang tidak berguna |
| 16 | 🔴 Bug Logika | `project_provider.dart` | `createProject()` tidak menyertakan `status: 'open'` → proyek tidak muncul di kontraktor |
| 17 | 🟡 UX | `kontraktor_detail_proyek_screen.dart` | Input harga penawaran diformat ribuan otomatis (20.000.000) |
| 18 | 🟢 Quality | `kontraktor_detail_proyek_screen.dart` | Polish UI: hero image, section spesifikasi, section lampiran (PDF + Maps) |
| 19 | 🟢 Quality | `pubspec.yaml` | Tambah dependency `url_launcher ^6.3.1` |

---

## Detail Perubahan per File

---

### 1. `lib/ui/client/screens/project_detail_screen.dart`
**Kategori:** 🔴 Bug Kritis (Runtime Crash)

**Masalah:**  
Screen ini menerima parameter `Map<String, dynamic>` tetapi dipanggil dari `progress_tab.dart` dengan objek `ProjectModel`. Ini menyebabkan **TypeError saat runtime** ketika user membuka detail proyek.

**Perubahan:**
- Tipe field `project` diubah dari `Map<String, dynamic>` → `ProjectModel`
- Tambah import `project_model.dart`
- Semua akses `project['key']` diubah ke properti model:
  - `project['image_urls']` → `project.imageUrls`
  - `project['title']` → `project.title`
  - `project['building_size']` → `project.buildingSize`
  - `project['floors']` → `project.floors`
  - `project['bedrooms']` → `project.bedrooms`

---

### 2. `lib/ui/kontraktor/screens/kontraktor_detail_proyek_screen.dart`
**Kategori:** 🔴 Bug Kritis (Runtime Crash) + 🟢 Memory Leak

**Masalah:**  
- Sama seperti #1: menerima `Map<String, dynamic>` tetapi dipanggil dengan `ProjectModel`.
- `_priceController` dan `_messageController` tidak pernah di-`dispose()`.

**Perubahan:**
- Tipe field `project` diubah dari `Map<String, dynamic>` → `ProjectModel`
- Tambah import `project_model.dart`
- Semua akses map diubah ke properti:
  - `widget.project['id']` → `widget.project.id ?? ''`
  - `widget.project['image_urls']` → `widget.project.imageUrls`
  - `widget.project['title']` → `widget.project.title`
  - `widget.project['description']` → `widget.project.description`
- Tambah method `dispose()` untuk kedua controller

---

### 3. `lib/ui/kontraktor/tabs/kontraktor_proyek_tab.dart`
**Kategori:** 🔴 Bug Kritis (Type Error) + 🟡 Performa (Infinite Request)

**Masalah:**
- `FutureBuilder<List<Map<String, dynamic>>>` — tipe salah, `fetchAvailableProjects()` mengembalikan `List<ProjectModel>`.
- Widget berupa `StatelessWidget` dengan `Consumer` wrapping `FutureBuilder` yang memanggil `fetchAvailableProjects()` setiap kali rebuild → **infinite network request**.

**Perubahan:**
- `FutureBuilder` type diubah: `List<Map<String, dynamic>>` → `List<ProjectModel>`
- Widget dikonversi: `StatelessWidget` → `StatefulWidget`
- Future di-cache di `initState()` via `_projectsFuture`
- `Consumer<ProjectProvider>` dihapus (tidak diperlukan lagi)

---

### 4. `lib/main.dart`
**Kategori:** 🔴 Keamanan

**Masalah:**  
Supabase URL dan anon key asli ter-hardcode sebagai `defaultValue` di `String.fromEnvironment()`. Siapapun yang clone repository bisa langsung mengakses database production.

**Perubahan:**
- `defaultValue` dihapus dari `SUPABASE_URL` dan `SUPABASE_ANON_KEY`
- Tambah `assert()` yang gagal cepat (*fail fast*) dengan pesan error yang jelas jika variabel tidak di-set

**Cara jalankan sekarang (wajib):**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

> **Rekomendasi lanjutan:** Buat file `.env` atau `launch.json` di lokal (masuk `.gitignore`) agar tidak perlu ketik manual setiap kali.

---

### 5. `lib/ui/auth/forgot_password_screen.dart`
**Kategori:** 🟡 Bug Fungsional + 🟢 Unused Imports

**Masalah:**
- Fungsi `_sendResetLink()` langsung navigate ke screen baru **tanpa** memanggil Supabase sama sekali → email reset tidak pernah terkirim.
- 2 import tidak digunakan: `password_strength.dart` dan `validators.dart`.

**Perubahan:**
- Hapus import `password_strength.dart` dan `validators.dart`
- Tambah import `supabase_flutter`
- Implementasi `_sendResetLink()` yang nyata:
  - Validasi email tidak kosong
  - Panggil `Supabase.instance.client.auth.resetPasswordForEmail(email)`
  - Tampilkan SnackBar sukses/gagal
  - Navigate ke `CreateNewPasswordScreen` hanya jika berhasil
  - Loading state saat proses berjalan

---

### 6. `lib/ui/auth/create_new_password_screen.dart`
**Kategori:** 🟡 Bug Fungsional

**Masalah:**  
`_saveNewPassword()` hanya mengubah state UI (`_isSuccess = true`) **tanpa** memanggil Supabase. Password pengguna tidak pernah benar-benar berubah.

**Perubahan:**
- Tambah import `supabase_flutter`
- Tambah field `_isLoading` dan `_errorText`
- Implementasi `_saveNewPassword()` yang nyata:
  - Panggil `auth.updateUser(UserAttributes(password: ...))`
  - Handle error dan tampilkan pesan di layar
  - Loading indicator pada tombol saat proses berjalan
- Tampilkan `_errorText` di atas tombol simpan jika ada error

---

### 7. `lib/ui/auth/role_screen.dart`
**Kategori:** 🟡 Bug Fungsional

**Masalah:**  
`AppBar` back button dikonfigurasi sebagai `onBack: () {}` — callback kosong yang tidak melakukan apa-apa.

**Perubahan:**
- `onBack: () {}` → `onBack: () => Navigator.pop(context)`

---

### 8–11. Infinite Network Request (4 File)
**Kategori:** 🟡 Performa

**File yang terdampak:**
- `lib/ui/client/tabs/progress_tab.dart`
- `lib/ui/client/tabs/contractor_tab.dart`
- `lib/ui/kontraktor/tabs/kontraktor_proyek_tab.dart`
- `lib/ui/kontraktor/tabs/kontraktor_profile_tab.dart`

**Masalah:**  
Semua widget ini memanggil fungsi `Future` (network request) langsung di dalam `build()` atau di dalam `Consumer.builder()`. Setiap kali widget rebuild (scroll, state change, dll), request ke Supabase dikirim ulang.

**Perubahan (sama untuk semua 4 file):**
- Konversi `StatelessWidget` → `StatefulWidget`
- Deklarasi `late Future _future` sebagai field
- Inisialisasi future sekali di `initState()`
- `FutureBuilder` menggunakan `_future` (cached), bukan memanggil fungsi langsung

**Bonus di `progress_tab.dart`:**
- Tambah tombol refresh (🔄) di AppBar agar user bisa reload data secara manual

---

### 12. `lib/ui/kontraktor/screens/kontraktor_detail_proyek_screen.dart`
*(Sudah dicakup di #2 — termasuk dispose())*

---

### 13. `lib/ui/kontraktor/screens/kontraktor_profileEdit_screen.dart`
**Kategori:** 🟢 Memory Leak

**Masalah:**  
File ini berisi 3 widget form (`_TabProfilForm`, `_TabPortoForm`, `_TabSertifForm`), masing-masing punya `TextEditingController` yang tidak pernah di-`dispose()`.

**Perubahan:**
- `_TabProfilFormState`: tambah `dispose()` untuk `_nameCtrl` dan `_companyCtrl`
- `_TabPortoFormState`: tambah `dispose()` untuk `_titleCtrl` dan `_yearCtrl`
- `_TabSertifFormState`: tambah `dispose()` untuk `_titleCtrl` dan `_issuerCtrl`

---

### 14. `lib/ui/client/screens/create_project_screen.dart`
**Kategori:** 🟢 Code Quality

**Masalah:**
- `_formKey` dideklarasikan dan dimasukkan ke `Form` widget, tetapi `_formKey.currentState?.validate()` **tidak pernah dipanggil** — form validation tidak aktif.
- URL fallback peta menggunakan Google Static Maps **tanpa API key** → gambar tidak akan muncul.

**Perubahan:**
- `_buildSmoothTextField()` ditambah parameter opsional `validator`
- Field judul proyek (`_titleController`) diberi validator wajib-isi
- `_submitData()` sekarang memanggil `_formKey.currentState?.validate()` sebelum submit
- URL fallback Google Maps diganti ke tile OpenStreetMap yang tidak butuh API key:
  - Sebelum: `https://maps.googleapis.com/maps/api/staticmap?...` (broken tanpa key)
  - Sesudah: `https://tile.openstreetmap.org/13/6508/4055.png`

---

### 15. `lib/ui/screens/onboarding_screen.dart`
**Kategori:** 🟢 Code Quality

**Masalah:**  
Conditional ternary pada `backgroundColor` tombol memiliki **kedua branch identik**:
```dart
// Sebelum (tidak ada bedanya)
backgroundColor: _currentPage == 2 ? const Color(0xFF8B2B0F) : const Color(0xFF8B2B0F),
```

**Perubahan:**
```dart
// Sesudah (disederhanakan)
backgroundColor: const Color(0xFF8B2B0F),
```

---

---

## Setup Environment (Lanjutan Fix #4 — Keamanan)

Karena credentials Supabase tidak lagi hardcoded, tim perlu melakukan setup berikut **sekali** di lokal masing-masing.

### File Baru yang Dibuat

| File | Status Git | Keterangan |
|------|------------|------------|
| `.vscode/launch.json` | ✅ Di-commit | Konfigurasi run VS Code/Cursor, membaca env vars otomatis |
| `.env.example` | ✅ Di-commit | Template — salin dan rename jadi `.env` |
| `.env` | 🚫 Di-ignore | File asli berisi credentials, **tidak boleh di-commit** |
| `.gitignore` | ✅ Di-commit | Ditambahkan entry `.env` |

### Cara Setup (Anggota Tim Baru)

```powershell
# 1. Copy template
cp .env.example .env

# 2. Buka .env, isi dengan credentials Supabase project
#    SUPABASE_URL=https://xxxx.supabase.co
#    SUPABASE_ANON_KEY=eyJ...

# 3. Set environment variable di terminal (sekali per sesi)
#    PowerShell:
$env:SUPABASE_URL     = "https://xxxx.supabase.co"
$env:SUPABASE_ANON_KEY = "eyJ..."

#    macOS / Linux:
# export SUPABASE_URL=https://xxxx.supabase.co
# export SUPABASE_ANON_KEY=eyJ...

# 4. Tekan F5 di VS Code → pilih "BuildMatch (Development)"
```

### Atau Run Manual via Terminal

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Konfigurasi launch.json

Tersedia dua konfigurasi di `.vscode/launch.json`:

| Nama | Mode | Kegunaan |
|------|------|----------|
| `BuildMatch (Development)` | debug | Development sehari-hari, hot reload aktif |
| `BuildMatch (Staging)` | profile | Test performa, mirip release tapi masih bisa profiling |

> **Catatan:** Warning `"type": "dart" not recognized` di editor adalah false positive dari schema validator generic. Di mesin yang sudah install **Flutter & Dart extension**, konfigurasi ini berjalan normal.

---

---

### 16. `lib/data/providers/project_provider.dart`
**Kategori:** 🔴 Bug Logika

**Masalah:**  
Method `createProject()` menyimpan proyek baru ke Supabase **tanpa menyertakan field `status`**. Karena `fetchAvailableProjects()` di sisi kontraktor mem-filter dengan `.eq('status', 'open')`, semua proyek yang dibuat klien tidak pernah muncul di Bursa Tender kontraktor (status = `null`).

**Perubahan:**
```dart
// Sebelum — field status tidak ada
await _supabase.from('projects').insert({
  'client_id': userId,
  'image_urls': ...,
  'reference_pdf_url': pdfUrl,
});

// Sesudah — tambah 1 baris
await _supabase.from('projects').insert({
  'client_id': userId,
  'image_urls': ...,
  'reference_pdf_url': pdfUrl,
  'status': 'open',  // ← FIX
});
```

---

### 17. `lib/ui/kontraktor/screens/kontraktor_detail_proyek_screen.dart`
**Kategori:** 🟡 UX — Format Input Harga

**Masalah:**  
Field input harga penawaran menerima angka mentah tanpa separator, sehingga sulit dibaca (contoh: `20000000`).

**Perubahan:**
- Tambah import `package:flutter/services.dart`
- Tambah class `_ThousandsSeparatorFormatter extends TextInputFormatter`:
  - Memformat digit secara realtime dengan titik ribuan (contoh: `20.000.000`)
  - Hanya menerima digit angka (`FilteringTextInputFormatter.digitsOnly`)
- `_submitBid()` dibersihkan dengan `.replaceAll('.', '')` sebelum `double.tryParse()` agar nilai terkirim benar ke database

---

### 18. `lib/ui/kontraktor/screens/kontraktor_detail_proyek_screen.dart`
**Kategori:** 🟢 Code Quality — Polish UI/UX

**Masalah:**  
Tampilan detail proyek tidak menampilkan spesifikasi teknis (budget, LT, LB, lantai, kamar), tidak ada fallback gambar, dan info lampiran klien (PDF, koordinat) tidak ditampilkan sama sekali.

**Perubahan:**

**Hero Image:**
- `Container` → `ClipRRect` + `Image.network` dengan `errorBuilder` dan `loadingBuilder`
- Tambah `BoxShadow` dan gradient overlay tipis (transparan → hitam 30%)
- Fallback icon jika gambar gagal load

**Blok Judul:**
- Font title: 22 → 24, weight 800, letterSpacing -0.3
- Tambah row nama klien (`clientName`) dengan icon `person_outline` di bawah judul

**Section Baru — Spesifikasi Proyek:**
- Grid 2 kolom × 4 baris dengan helper `_specChip()`
- Info yang ditampilkan: Anggaran, Luas Tanah, Luas Bangunan, Lantai, Kamar Tidur, Kamar Mandi, Gaya, Lokasi
- Menggunakan `AppFormatters.formatRupiah()` untuk format budget

**Section Baru — Lampiran Klien (kondisional):**
- Muncul hanya jika `referencePdfUrl` atau koordinat tersedia
- Tile PDF: buka URL di browser/PDF viewer eksternal via `url_launcher`
- Tile Maps: buka Google Maps dengan koordinat via `url_launcher`
- Helper `_attachmentTile()` untuk konsistensi tampilan

**Form Penawaran:**
- Header ditambah icon `gavel_rounded` + sub-text helper
- Field harga: prefix `Rp` permanent, font 18 semibold
- Field pesan: hint placeholder informatif

**Tombol Submit:**
- `ElevatedButton` → `ElevatedButton.icon` dengan icon `send_rounded`
- Tambah `BoxShadow` glow warna primary
- State loading: spinner kecil (22px) + teks `'Mengirim...'`

---

### 19. `pubspec.yaml`
**Kategori:** 🟢 Dependency Baru

**Alasan:**  
Dibutuhkan untuk membuka URL eksternal (PDF referensi dan Google Maps) dari section Lampiran Klien di #18.

**Perubahan:**
```yaml
# Ditambahkan:
url_launcher: ^6.3.1  # → resolved ke 6.3.2
```

---

## Hal yang Belum Diubah (Backlog)

Beberapa masalah yang ditemukan saat review namun **sengaja tidak diubah** karena bersifat arsitektural dan butuh diskusi tim:

- **Data dummy hardcoded** — statistik di `profile_tab.dart`, `kontraktor_home_tab.dart`, daftar proyek di profile, kontraktor terpopuler di beranda. Perlu disambungkan ke query Supabase yang nyata.
- **Chat `user_2` hardcoded** — `chat_page.dart` perlu menerima `receiverId` sebagai parameter agar fungsional.
- **`consult_tab.dart` kosong** — file kosong, perlu diisi atau dihapus.
- **`NeonGlassCard` salah folder** — widget ini ada di `core/utils/` tapi seharusnya di `core/widgets/`. Tidak digunakan di manapun.
- **Duplikasi kode di `register_screen.dart`** — widget password strength dan field helper masih duplikat dari shared widgets.
- **`dart:io` tidak kompatibel web** — seluruh fitur upload file tidak akan jalan di platform web.

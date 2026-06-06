# Walkthrough: Fitur Chat & Reorganisasi Tab Mitra

Seluruh pekerjaan untuk mengimplementasikan fitur chat Klien-Kontraktor, memperbaiki visibilitas label, serta melakukan restrukturisasi tab Mitra dan Konsultasi telah berhasil diselesaikan.

## Perubahan yang Dilakukan

### 1. Perbaikan Label Peran ("Arsitek" / "Kontraktor")
- **Penyebab Masalah:** Row layout pada nama pengirim di list Inbox dibatasi secara ketat sehingga nama yang panjang mendominasi lebar card dan memotong (menyembunyikan) badge label peran di ujung kanan.
- **Solusi:** 
  - Mengubah struktur Row pada [consultasi_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/consultasi_tab.dart) dan [chat_list_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/shared/screens/chat_list_screen.dart). Nama dibungkus dengan `Flexible` dan diletakkan berdampingan dengan badge di dalam sub-Row `Expanded`. Ini memastikan nama yang sangat panjang akan dipotong dengan ellipsis (`TextOverflow.ellipsis`) tanpa menggeser atau menyembunyikan badge peran.
  - Membatasi visibilitas badge peran agar **hanya muncul di sisi klien** (`isClientSide ? chat.vendorRole : null`) agar di sisi vendor/kontraktor tidak muncul badge yang membingungkan.

### 2. Penggabungan Tab Mitra (Kontraktor + Arsitek)
- **File Baru:** [mitra_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/mitra_tab.dart)
  - Menggabungkan daftar kontraktor (sebelumnya di `contractor_tab.dart`) dan daftar arsitek (sebelumnya di `consultasi_tab.dart`) ke dalam satu TabView dengan dua tab filter: **Kontraktor** dan **Arsitek**.
  - Fitur pencarian, profil Hero tag, style chips, tombol "Lihat Profil", dan tombol "Konsultasi" semuanya dipertahankan dengan perilaku yang sama persis seperti sebelumnya.
- **Backwards Compatibility:** Mengubah isi [contractor_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/contractor_tab.dart) menjadi `export 'mitra_tab.dart';` untuk mencegah error kompilasi dan memelihara kompatibilitas referensi.

### 3. Penyederhanaan Tab Konsultasi (Inbox Saja)
- **File:** [consultasi_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/consultasi_tab.dart)
  - Menghapus komponen TabBar dan TabBarView dari halaman konsultasi. Halaman ini sekarang langsung memuat bilah pencarian dan daftar Inbox percakapan secara ringkas.
  - Jika kotak masuk kosong, tombol "Cari Mitra" akan dialihkan untuk mengarahkan pengguna secara otomatis ke Tab Mitra.

### 4. Navigasi & Redirect Pintar
- **File:** [main_nav.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/shared/screens/main_nav.dart)
  - Mengubah label tab bar klien index 1 dari `'Kontraktor'` menjadi `'Mitra'` dengan icon `Icons.groups_outlined`.
  - Mengimplementasikan callback `_handleSwitchTab(int index)`. Jika navigasi menerima index `99` (penanda redirect ke arsitek), sistem akan memindahkan tab utama ke index 1 (Mitra) dan menginstruksikan `MitraTab` untuk langsung membuka sub-tab **Arsitek** (index 1).
- **File:** [beranda_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/beranda_tab.dart) & [progress_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/progress_tab.dart)
  - Mengubah pemanggilan `onSwitchTab` dari index `2` menjadi `99` ketika mendeteksi event `'route_to_consultation'` dari form Step 4/chip 4 "Hubungi Arsitek".
  - Mengubah tautan klik "Cari Arsitek" di menu utama `beranda_tab.dart` agar mengarah ke index `99` (Mitra > Arsitek).

---

## Panduan Verifikasi Manual

1. **Uji Penamaan & Visibilitas Badge**:
   - Buka tab **Konsultasi**.
   - Perhatikan nama mitra. Nama yang panjang tetap menyisakan ruang yang cukup untuk badge **Arsitek** atau **Kontraktor** di ujung kanan.
   - Masuk ke akun **Vendor / Kontraktor** dan buka inbox. Pastikan badge peran tidak muncul di samping nama klien (karena penerima adalah klien).

2. **Uji Tab Mitra**:
   - Buka tab **Mitra** di bilah navigasi bawah (menggantikan nama 'Kontraktor').
   - Geser tab antara **Kontraktor** dan **Arsitek**. Pastikan daftar masing-masing mitra termuat dengan benar.
   - Ketuk "Konsultasi" pada salah satu arsitek untuk memastikan fungsi chat/buka profil arsitek tetap berjalan normal.

3. **Uji Redirect Step 4 (Hubungi Arsitek)**:
   - Buat proyek baru sebagai Klien, isi data hingga Step 4.
   - Ketuk tautan **"Hubungi arsitek dan buat design yang kamu inginkan"**.
   - Setelah konfirmasi dialog sukses draft disimpan, pastikan tab otomatis berpindah ke tab **Mitra** dan langsung fokus pada daftar **Arsitek** (Tab ke-2), bukan Kontraktor.

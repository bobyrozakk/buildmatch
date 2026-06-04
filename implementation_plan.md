# Rencana Implementasi: Penyesuaian Form Buat Proyek Baru

Rencana ini dibuat untuk memindahkan inputan "Luas Bangunan" dari Step 2 ke Step 3 (bersamaan dengan Luas Tanah dan Budget), menambahkan batasan ukuran (limit) untuk luas tanah custom dan luas bangunan guna mencegah input tidak wajar (crash), serta mengubah pemilihan tipe rumah di Step 2 menjadi grid card 2 kolom dengan gambar preview dan fallback visual.

## User Review Required

> [!NOTE]
> **Struktur Folder Gambar & Konfigurasi Assets**
> Gambar-gambar yang Anda kirimkan perlu dimasukkan ke dalam folder `lib/ui/client/assets/images/house_styles/` di dalam project. File-file tersebut harus dinamai sesuai tipe rumahnya (format `.jpg` huruf kecil):
> - Minimalis -> `minimalis.jpg`
> - Modern -> `modern.jpg`
> - Klasik -> `klasik.jpg`
> - Tropis -> `tropis.jpg`
> - Industrial -> `industrial.jpg`
> 
> Kode yang saya siapkan sudah menggunakan penamaan ini dan memiliki mekanisme **fallback** (jika gambar belum ditaruh di aset/belum dimasukkan ke dalam `pubspec.yaml`, aplikasi tetap berjalan aman tanpa crash dan menampilkan placeholder yang elegan).

## Proposed Changes

### Configuration Component

#### [MODIFY] [pubspec.yaml](file:///c:/KuliahRifat/semester4/pbl/buildmatch/pubspec.yaml)
- Mendaftarkan folder aset `lib/ui/client/assets/images/house_styles/` agar dibaca oleh Flutter.

### UI Screens Component

#### [MODIFY] [create_project_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/screens/create_project_screen.dart)

1. **Pemindahan & Logika Luas Bangunan:**
   - Hapus input text field "Luas Bangunan" dari `_buildStep2()`.
   - Tambahkan input text field "Luas Bangunan" di `_buildStep3()`, diletakkan setelah pilihan template/custom luas tanah dan sebelum slider/card "Budget Anda".
   - Perbarui getter `_maxBuildingSize` agar membatasi luas bangunan maksimum ke `min(90% luas tanah, 500 m²)`.
   - Perbarui pesan peringatan realtime di bawah text field untuk menampilkan batas 500 m² tersebut.

2. **Pembatasan Luas Tanah Custom:**
   - Perbarui `_validateStep3()` untuk membatasi panjang dan lebar tanah custom maksimal **200 meter** masing-masing (sehingga total luas tanah maksimal 40.000 m²).
   - Validasi bahwa luas bangunan tidak boleh melebihi `_maxBuildingSize` (maks 500 m²).

3. **Gambar Contoh Tipe Rumah (Card Grid):**
   - Buat fungsi pembantu `_buildHouseStyleCard(String style)` untuk merender card gaya rumah.
   - Menggunakan `Image.asset` dengan `errorBuilder` untuk menangani gambar yang belum disalin ke folder aset agar tidak crash.
   - Mengubah ChoiceChip "Tipe Rumah" di `_buildStep2()` menjadi `GridView.count` berkolom 2 yang memanggil `_buildHouseStyleCard` untuk kelima gaya rumah.

4. **Validasi Alur Stepper:**
   - Perbarui `_validateStep2()` agar tidak lagi memvalidasi luas bangunan (karena belum diisi di step 2).
   - Perbarui `_validateStep3()` untuk melakukan validasi luas bangunan dan spesifikasi bangunan penuh (kamar tidur, kamar mandi, lantai) terhadap luas tanah yang dipilih.

## Verification Plan

### Automated/Manual Verification
- Kita akan memverifikasi penulisan kode di `create_project_screen.dart` and `pubspec.yaml`.
- Uji alur pembuatan proyek dari Step 1 sampai Step 4 untuk memastikan transisi step dan penyimpanan draft berjalan lancar.

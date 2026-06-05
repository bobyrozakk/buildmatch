# Walkthrough: Perbaikan Slider & Redirect Draft ke Konsultasi Arsitek

Pekerjaan untuk memperbaiki crash pada slider anggaran (budget) ketika melakukan spam input serta penambahan tautan redirect draf proyek ke konsultasi arsitek telah selesai.

## Perubahan yang Dilakukan

1. **Perbaikan Crash Slider Anggaran (Reaktif & Aman):**
   - **File:** [create_project_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/screens/create_project_screen.dart)
   - **Penyebab Bug:** Ketika user memasukkan luas tanah custom yang sangat besar (panjang/lebar di atas 200m yang dipotong menjadi 200m), anggaran minimum (`effectiveMin`) melonjak hingga **Rp 96 Miliar** (atau **9.6 Miliar**). Hal ini memaksa nilai `_budget` ikut melonjak ke angka tersebut. Namun, saat input diperbaiki/dikecilkan, nilai `_budget` tetap berada di Rp 96 Miliar, padahal batas maximum budget baru (`_maxBudget`) ikut turun menjadi **Rp 20 Miliar**. Akibatnya, parameter Slider bernilai `value = 96 Miliar`, `min = 9.6 Miliar`, dan `max = 20 Miliar`, sehingga memicu Flutter assertion crash (`value <= max`).
   - **Solusi:**
     - Menambahkan validasi reaktif di dalam `_onCustomLandChanged()` untuk melakukan *clamping* otomatis jika nilai `_budget` yang lama melebihi batas maximum budget yang baru dihitung.
     - Melakukan *guards clamping* secara langsung di dalam fungsi pembangun slider (`_buildBudgetCard()`) dengan memaksa nilai `value` selalu berada di antara `min` dan `max` yang valid, menjamin tidak akan terjadi red-screen assertion crash meskipun ada jeda waktu reaktif keyboard.

2. **Penambahan Link Hubungi Arsitek (Redirect Draft):**
   - **File:** [create_project_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/screens/create_project_screen.dart)
     - Menambahkan fungsi `_saveDraftAndConsultArchitect()` untuk memicu penyimpanan draf proyek ke Supabase.
     - Menambahkan alert dialog sukses menggunakan `showDialog` yang menginformasikan bahwa proyek berhasil disimpan ke draft sebelum diarahkan.
     - Menyediakan link berformat huruf href bergaris bawah `"Hubungi arsitek dan buat design yang kamu inginkan"` di Step 4 (di bawah upload PDF). Ketika ditekan, draf disimpan dan mengembalikan string rute `'route_to_consultation'`.
   - **File:** [beranda_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/beranda_tab.dart) & [progress_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/progress_tab.dart)
     - Menambahkan parameter `onSwitchTab` ke tab draf/progress untuk mendengarkan kembalian dari pembuatan draf. Jika menerima `'route_to_consultation'`, tab navigasi utama akan otomatis beralih ke tab Konsultasi (index 2).
   - **File:** [main_nav.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/shared/screens/main_nav.dart)
     - Mengubah instansiasi `ProgressTab` untuk mengirimkan callback `onSwitchTab` agar dapat meredirect user secara global.

## Uji Coba & Hasil Verifikasi
Analisis struktur kode statis memastikan penanganan state di Flutter berjalan aman tanpa kendala referensi. Penanganan bounds pada widget Slider dipastikan mathematically safe.

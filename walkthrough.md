# Walkthrough: Penyesuaian Form Buat Proyek Baru & Desain Tipe Rumah

Pekerjaan untuk memindahkan inputan "Luas Bangunan" ke Step 3, mengimplementasikan limit ukuran untuk mencegah crash akibat input tidak wajar, serta menambahkan preview gambar gaya rumah pada Step 2 telah selesai dikerjakan.

## Perubahan yang Dilakukan

1. **Konfigurasi Aset Gambar (`pubspec.yaml`):**
   - Mendaftarkan path folder assets `lib/ui/client/assets/images/house_styles/` agar dibaca oleh Flutter saat dijalankan.

2. **Peningkatan Form Pembuatan Proyek (`lib/ui/client/screens/create_project_screen.dart`):**
   - **Step 2 (Spesifikasi Bangunan):**
     - Menghapus input field "Luas Bangunan".
     - Mengganti ChoiceChip "Tipe Rumah" menjadi grid card 2 kolom yang interaktif (`_buildHouseStyleCard`). Card ini memuat gambar dari asset, overlay teks nama gaya rumah, dan indikator terpilih.
     - Ditambahkan penanganan kesalahan (`errorBuilder`) pada pemuatan gambar asset. Jika gambar belum diletakkan di folder atau tidak ditemukan, aplikasi akan menampilkan placeholder visual yang elegan tanpa crash.
   - **Step 3 (Estimasi Budget):**
     - Menambahkan input field "Luas Bangunan" di bawah input luas tanah (baik template maupun custom), dan sebelum penentuan budget.
     - Menampilkan info/warning card secara dinamis jika luas bangunan melebihi batas yang diperbolehkan.
    - **Validasi & Limit Ketat:**
      - Luas tanah custom (panjang dan lebar) dibatasi maksimal **200 meter** masing-masing. Diimplementasikan fungsi pembatas reaktif reaktif (`_onCustomLandChanged`), di mana jika pengguna mengetik angka di atas 200, input akan secara otomatis terpotong ke 200 untuk mencegah user iseng memasukkan angka jutaan meter.
      - Luas bangunan dibatasi maksimal **min(90% luas tanah, 20.000 m²)**. Pembatasan ini berjalan secara reaktif (`_onBuildingSizeChanged`), sehingga jika pengguna mengetik di atas 20.000, input akan otomatis terpotong ke 20.000.
      - Menyesuaikan `_validateStep2()` dan `_validateStep3()` untuk mengakomodasi alur stepper baru dan memvalidasi spesifikasi bangunan secara menyeluruh terhadap luas tanah yang dipilih.

## Uji Coba & Hasil Verifikasi

Meningat keterbatasan eksekusi shell lokal, pengujian dilakukan dengan peninjauan statis kode (static analysis):
- Seluruh referensi tipe data dan variabel lokal dipastikan sesuai.
- Pustaka `dart:math` dipastikan sudah diimpor untuk menghitung limit dinamis `math.min`.
- Pemuatan `Image.asset` memiliki fallback `errorBuilder` sehingga aman meskipun gambar belum dimasukkan.

### Penempatan File Gambar
Untuk memasukkan gambar yang sudah Anda kirimkan, silakan buat folder baru (jika belum ada) dan letakkan kelima file gambar di:
`lib/ui/client/assets/images/house_styles/`

Dengan nama file sebagai berikut:
- **Gedung gelap dengan rangka besi** -> `industrial.jpg`
- **Rumah 1 lantai minimalis, atap hitam** -> `minimalis.jpg`
- **Rumah 2 lantai dengan gerbang hitam** -> `modern.jpg`
- **Rumah banyak tanaman hijau** -> `tropis.jpg`
- **Rumah gaya Eropa/klasik** -> `klasik.jpg`

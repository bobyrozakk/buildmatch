# Walkthrough: Fitur Chat Klien ↔ Kontraktor

Fitur chat antara Klien dan Kontraktor telah selesai diimplementasikan secara menyeluruh tanpa mengubah skema tabel database utama Supabase (menggunakan kueri dinamis join profiles role).

## Perubahan yang Dilakukan

1. **Model Chat (`chat_model.dart`)**:
   - Menambahkan field `clientRole` dan `vendorRole` pada [chat_model.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/data/models/chat_model.dart) untuk menyimpan peran pengguna dari tabel `profiles`.
   - Mengupdate method `ChatModel.fromJson` agar mengambil nilai role dari objek join profil `client` dan `vendor`.

2. **Provider Chat (`chat_provider.dart`)**:
   - Memperbarui method `fetchChats` pada [chat_provider.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/data/providers/chat_provider.dart) untuk mengambil field `role` dari join profil client dan vendor di Supabase.
   - Menambahkan parameter opsional `forceStatus` pada method `getOrCreateChat()` agar chat dapat diinisialisasi langsung dengan status `'accepted'` (sehingga chat room langsung aktif tanpa proses persetujuan arsitek).

3. **Room Chat Kontraktor (`contractor_chat_detail_screen.dart`)**:
   - Membuat screen baru [contractor_chat_detail_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/shared/screens/contractor_chat_detail_screen.dart) khusus untuk obrolan dengan kontraktor.
   - Menyederhanakan UI dengan hanya menyisakan pesan teks, lampiran gambar, dan lampiran file PDF/dokumen.
   - Menghapus fungsionalitas penawaran arsitek, pengiriman draf desain, term pembayaran, status nego, dan banner accept/reject permintaan obrolan.
   - Mempertahankan visual design premium yang sama persis seperti room chat arsitek (warna gelembung, format waktu, tick read receipt, popup pemilihan berkas, limitasi ukuran berkas 5MB, dan kompresi gambar 70% quality).

4. **Detail Penawaran Kontraktor (`bid_detail_screen.dart`)**:
   - Memodifikasi [bid_detail_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/screens/bid_detail_screen.dart) untuk menampilkan tombol **Hubungi Kontraktor** di bagian paling bawah.
   - Tombol ini diposisikan di dalam `bottomNavigationBar` sehingga selalu melayang (sticky) baik saat bid berstatus pending, diterima, maupun saat proyek sudah berjalan.
   - Menambahkan method `_handleContactContractor` untuk menginisiasi chat menggunakan `getOrCreateChat` dengan `forceStatus: 'accepted'`, menampilkan dialog loading, dan menavigasi klien ke `ContractorChatDetailScreen`.

5. **Visual Badge & Rute Navigasi Inbox (`consultasi_tab.dart` & `chat_list_screen.dart`)**:
   - Memodifikasi [consultasi_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/consultasi_tab.dart) (Inbox sisi klien) dan [chat_list_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/shared/screens/chat_list_screen.dart) (Inbox sisi vendor).
   - Menambahkan method pembantu `_buildRoleBadge` untuk menampilkan chip penanda berlabel **Arsitek** (warna biru lembut) atau **Kontraktor** (warna oranye lembut) di sebelah nama vendor pada card chat list.
   - Memperbarui rute navigasi ketika card chat diklik: jika vendor teridentifikasi memiliki role `'vendor'` atau `'kontraktor'`, maka navigasi diarahkan ke `ContractorChatDetailScreen`. Jika tidak, akan diarahkan ke `ChatDetailScreen` arsitek.

## Panduan Verifikasi Manual

### 1. Memulai Chat dari Detail Penawaran Kontraktor
- Masuk sebagai **Client**.
- Buka detail proyek Anda yang telah diajukan penawaran (bidding) oleh kontraktor.
- Masuk ke detail penawaran kontraktor tersebut dengan menekan **Lihat Detail**.
- Scroll ke bawah dan tekan tombol **Hubungi Kontraktor**.
- Pastikan loading indicator muncul sejenak dan Anda langsung dialihkan ke room chat dengan status obrolan aktif.

### 2. Mengirim Pesan dan Lampiran
- Di room chat kontraktor, coba kirim pesan teks.
- Tekan tombol **+** (Lampiran) di sebelah kiri input text.
- Pilih opsi **Foto / Galeri** (pastikan gambar dikirim dengan terkompresi) atau pilih **Dokumen / File** (pastikan file format PDF/dokumen terkirim dengan batasan ukuran 5MB).
- Pastikan berkas terkirim dan tersimpan di bucket Supabase `documents`.

### 3. Membuka Kembali Lewat Tab Konsultasi > Inbox
- Kembali ke beranda aplikasi.
- Buka tab **Konsultasi** -> sub-tab **Inbox**.
- Cari percakapan dengan kontraktor tersebut.
- Pastikan ada badge chip berwarna oranye bertuliskan **Kontraktor** di ujung nama kontraktor tersebut.
- Ketuk card chat tersebut dan pastikan Anda diarahkan kembali ke `ContractorChatDetailScreen` (room chat kontraktor sederhana).
- Ketuk card chat arsitek lain dan pastikan Anda tetap diarahkan ke `ChatDetailScreen` (room chat arsitek lengkap dengan opsi pembayaran/penawaran).

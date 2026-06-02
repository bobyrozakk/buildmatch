# Rangkuman Pekerjaan — Fitur Chat, Pembayaran, dan Pengiriman Desain Arsitek

Semua komponen untuk alur obrolan (chat), penawaran, pembayaran virtual account, dan peninjauan desain antara Klien dan Arsitek telah selesai diimplementasikan. Berikut adalah rangkuman dari perubahan dan fitur-fitur baru yang telah dipasang.

---

## 🛠️ Perubahan & Penambahan Kode

### 1. Model & Provider
*   **[architect_provider.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/data/providers/architect_provider.dart)**: Menambahkan `editArchitectOffer`, `cancelArchitectOffer`, dan `fetchBidById` untuk mengelola penawaran arsitek sebelum pembayaran dilakukan.
*   **[project_provider.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/data/providers/project_provider.dart)**: Menambahkan `createArchitectPaymentTerm` (membuat 1 termin pembayaran 100% untuk desain), `architectConfirmClientPayment` (konfirmasi pembayaran diterima), dan `submitDesignFiles` (menyerahkan tautan berkas desain).

### 2. Antarmuka Pengguna (UI)
*   **[architect_offer_detail_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/screens/architect_offer_detail_screen.dart)**: Layar klien untuk melihat rincian penawaran arsitek, memilih bank transfer (BCA, BNI, Mandiri, BRI), mendapatkan nomor Virtual Account acak, dan mengklaim "Saya Sudah Membayar".
*   **[client_design_review_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/screens/client_design_review_screen.dart)**: Layar klien untuk meninjau berkas desain yang diserahkan arsitek, membuka berkas, menyetujui secara formal, atau mengajukan revisi berdasarkan kuota revisi yang tersisa.
*   **[kirim_desain_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/arsitek/screens/kirim_desain_screen.dart)**: Menyelesaikan logika pengiriman desain arsitek. Mendukung multi-file pick (`dwg`, `dxf`, `pdf`, `jpg`, `png`), validasi ukuran (< 5MB per file), limitasi foto (maks. 10 berkas foto), pengunggahan ke Supabase Storage, dan pengiriman kartu desain ke chat.
*   **[chat_detail_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/shared/screens/chat_detail_screen.dart)**: 
    *   Mendukung sinkronisasi status pembayaran real-time (`pending`, `paid`, `confirmed`, `submitted`, `revision_requested`, `completed`).
    *   Menonaktifkan tombol "Kirim Desain" di bar lampiran apabila penawaran belum dibayar/dibuat.
    *   Menambahkan tombol **Konfirmasi Pembayaran** untuk arsitek ketika status pembayaran adalah `paid` (waiting_confirmation).
    *   Memperbarui kartu pesan pengiriman desain agar langsung menavigasi ke layar peninjauan klien.

---

## 🔄 Alur Kerja yang Diuji & Berfungsi

1.  **Pengiriman Penawaran**: Arsitek membuat penawaran via `BuatPenawaranSheet`. Kartu penawaran JSON dikirim ke obrolan secara instan.
2.  **Edit / Batalkan**: Selama klien belum membayar, arsitek dapat mengedit harga/revisi atau membatalkan penawaran secara langsung.
3.  **Pembayaran Virtual Account**: Klien menekan "Lihat & Bayar Penawaran" di chat, memilih bank, menyalin nomor VA, lalu menekan "Saya Sudah Membayar". Status berubah menjadi `waiting_confirmation` (`paid` di obrolan).
4.  **Aktivasi Proyek**: Arsitek memverifikasi uang masuk dan menekan "Konfirmasi Pembayaran" di chat. Status proyek berubah menjadi `in_progress`, bid disetujui (`accepted`), dan tombol "Kirim Desain" milik arsitek menjadi aktif.
5.  **Pengiriman Desain**: Arsitek mengunggah file AutoCAD/PDF/Foto (ukuran per file dicek < 5MB, maks. 10 gambar), menulis catatan, lalu mengirimkannya.
6.  **Tinjau & Revisi**: Klien meninjau kiriman desain di layar review. Klien dapat mengajukan revisi (mengurangi kuota sisa revisi) atau menekan "Setujui Desain" untuk menandai proyek selesai (100% progress).

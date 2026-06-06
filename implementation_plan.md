# Rencana Implementasi: Fitur Chat Klien ↔ Kontraktor

Rencana ini dibuat untuk menambahkan fitur chat antara Klien dan Kontraktor, mirip dengan fitur chat Klien-Arsitek yang sudah ada, namun disederhanakan tanpa kartu penawaran (offer cards) atau alur pembayaran di dalam room chat. Alur chat dimulai dari tombol "Hubungi Kontraktor" pada detail penawaran kontraktor (`BidDetailScreen`). Percakapan tersebut juga dapat diakses kembali dari tab konsultasi di bagian Inbox dengan badge penanda "Kontraktor" atau "Arsitek".

## User Review Required

> [!IMPORTANT]
> **Integrasi Tanpa Migrasi Database Tambahan**
> Rencana ini **tidak memerlukan migrasi atau perubahan skema tabel di Supabase**. Kita memanfaatkan relasi profile join yang sudah ada untuk mengambil data kolom `role` dari tabel `profiles` secara dinamis.
> Status chat untuk kontraktor yang dimulai oleh client akan diset ke `'accepted'` secara langsung sehingga room chat aktif seketika tanpa memerlukan konfirmasi persetujuan (pending/accept flow) seperti pada arsitek.

## Proposed Changes

### 1. Data Models

#### [MODIFY] [chat_model.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/data/models/chat_model.dart)
- Tambahkan properti `clientRole` dan `vendorRole` (keduanya `String?`) ke kelas `ChatModel`.
- Perbarui konstruktor dan factory `ChatModel.fromJson` untuk membaca field ini dari relasi data profil yang di-join (`client` dan `vendor`).

---

### 2. Providers

#### [MODIFY] [chat_provider.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/data/providers/chat_provider.dart)
- Perbarui kueri di `fetchChats()` untuk menambahkan `role` di dalam kueri profiles (`client:client_id(name, avatar_url, role)` dan `vendor:vendor_id(name, avatar_url, role)`).
- Petakan data role tersebut ke `ChatModel` saat parsing respons database.
- Perbarui `getOrCreateChat()` dengan menambahkan parameter opsional `forceStatus` (misal `'accepted'`) agar client dapat langsung membuka chat aktif dengan kontraktor tanpa melalui status `'pending'`.

---

### 3. UI Screens & Components

#### [NEW] [contractor_chat_detail_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/shared/screens/contractor_chat_detail_screen.dart)
- Buat screen room chat baru khusus untuk kontraktor dengan gaya UI yang sama persis seperti `chat_detail_screen.dart` (menggunakan warna latar belakang, bubble chat, double tick read receipt, popup upload/kompresi lampiran file/foto).
- **Hapus** seluruh komponen kartu penawaran (offer card), kartu draf desain (design card), status draf, tombol pembayaran, dan banner tolak/terima permintaan di bagian atas/bawah. Hanya menampilkan pesan teks, foto, dan file PDF/dokumen.

#### [MODIFY] [bid_detail_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/screens/bid_detail_screen.dart)
- Tambahkan tombol **Hubungi Kontraktor** di bagian paling bawah.
  - Jika status bid adalah `pending` dan proyek belum in_progress, tampilkan di bawah tombol "Tolak" dan "Terima Penawaran" dalam layout Column.
  - Jika status bid selain `pending` (atau proyek sudah berjalan), tombol ini akan tampil sebagai tombol utama/satu-satunya di `bottomNavigationBar` sehingga client selalu bisa menghubungi kontraktor.
  - Aksi tombol: memanggil `ChatProvider.getOrCreateChat` dengan `projectId: bid.projectId` dan `forceStatus: 'accepted'`, lalu navigasi ke `ContractorChatDetailScreen`.

#### [MODIFY] [consultasi_tab.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/client/tabs/consultasi_tab.dart)
- Tambahkan fungsi pembantu `_buildRoleBadge(String? role)` untuk menampilkan chip penanda peran (`Arsitek` / `Kontraktor`) di ujung nama dalam setiap card percakapan (Inbox).
- Perbarui aksi ketukan `onTap` pada card chat di tab Inbox:
  - Jika `chat.vendorRole` adalah `'vendor'` atau `'kontraktor'`, arahkan ke `ContractorChatDetailScreen`.
  - Jika `chat.vendorRole` adalah `'architect'` atau `'arsitek'`, arahkan ke `ChatDetailScreen` (arsitek).

#### [MODIFY] [chat_list_screen.dart](file:///c:/KuliahRifat/semester4/pbl/buildmatch/lib/ui/shared/screens/chat_list_screen.dart)
- Lakukan hal yang sama seperti di tab konsultasi: tambahkan chip penanda peran (`Arsitek` / `Kontraktor`) dan sesuaikan navigasi `onTap` agar mengarah ke detail screen yang sesuai berdasarkan peran vendor.

## Verification Plan

### Manual Verification
1. **Inisiasi Chat**:
   - Masuk sebagai Client, buka detail proyek yang memiliki penawaran dari kontraktor.
   - Masuk ke detail penawaran kontraktor tersebut, temukan tombol **Hubungi Kontraktor**.
   - Tekan tombol dan pastikan langsung diarahkan ke room chat dengan kontraktor tersebut tanpa banner pending.
2. **Kirim Pesan & Lampiran**:
   - Kirim pesan teks.
   - Unggah foto dari galeri (pastikan terkompresi dengan baik) dan kirim.
   - Unggah file PDF/dokumen (maksimal 5MB) dan kirim.
3. **Akses Inbox**:
   - Kembali ke halaman utama, buka Tab Konsultasi -> Inbox.
   - Pastikan terdapat badge **Kontraktor** di sebelah nama kontraktor dan badge **Arsitek** di sebelah nama arsitek.
   - Tekan kembali chat kontraktor dan pastikan membuka room chat kontraktor (`ContractorChatDetailScreen`).
   - Tekan chat arsitek dan pastikan membuka room chat arsitek lama (`ChatDetailScreen`).

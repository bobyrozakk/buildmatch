# Tasks - Fitur Chat Klien ↔ Kontraktor & Tab Mitra

- [x] Modifikasi `ChatModel` di `lib/data/models/chat_model.dart` (tambah `clientRole` & `vendorRole`)
- [x] Modifikasi `ChatProvider` di `lib/data/providers/chat_provider.dart` (fetch metadata role, status override)
- [x] Buat screen `ContractorChatDetailScreen` di `lib/ui/shared/screens/contractor_chat_detail_screen.dart`
- [x] Modifikasi `BidDetailScreen` di `lib/ui/client/screens/bid_detail_screen.dart` (tambah tombol Hubungi Kontraktor)
- [x] Buat dan rename `MitraTab` di `lib/ui/client/tabs/mitra_tab.dart` (menggabungkan list Kontraktor & Arsitek)
- [x] Sederhanakan `ConsultasiTab` di `lib/ui/client/tabs/consultasi_tab.dart` (hanya menampilkan Inbox, hapus tab Arsitek)
- [x] Modifikasi `main_nav.dart` (ganti `ContractorTab` ke `MitraTab`, ubah nama label ke 'Mitra', pasang logic switchTab 99)
- [x] Perbarui pemanggilan callback redirect di `beranda_tab.dart` dan `progress_tab.dart` (index 2 -> 99)
- [x] Perbaiki visual badge role label agar tidak terpotong (menggunakan Row + Expanded + Flexible)
- [x] Tampilkan badge role label hanya untuk sisi klien di inbox
- [x] Verifikasi dan uji fungsionalitas secara statis

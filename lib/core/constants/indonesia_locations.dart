/// Curated daftar provinsi & kota utama di Indonesia.
/// Hanya kota-kota utama per provinsi agar picker tetap minimalis.
class IndonesiaLocations {
  IndonesiaLocations._();

  /// Map provinsi -> daftar kota utama.
  static const Map<String, List<String>> data = {
    'Aceh': ['Banda Aceh', 'Lhokseumawe', 'Langsa', 'Sabang'],
    'Sumatera Utara': ['Medan', 'Binjai', 'Tebing Tinggi', 'Pematangsiantar'],
    'Sumatera Barat': ['Padang', 'Bukittinggi', 'Payakumbuh', 'Padang Panjang'],
    'Riau': ['Pekanbaru', 'Dumai'],
    'Kepulauan Riau': ['Batam', 'Tanjung Pinang'],
    'Jambi': ['Jambi', 'Sungai Penuh'],
    'Sumatera Selatan': ['Palembang', 'Lubuklinggau', 'Prabumulih', 'Pagar Alam'],
    'Bangka Belitung': ['Pangkal Pinang'],
    'Bengkulu': ['Bengkulu'],
    'Lampung': ['Bandar Lampung', 'Metro'],
    'DKI Jakarta': ['Jakarta Pusat', 'Jakarta Utara', 'Jakarta Selatan', 'Jakarta Barat', 'Jakarta Timur'],
    'Jawa Barat': ['Bandung', 'Bekasi', 'Bogor', 'Depok', 'Cimahi', 'Cirebon', 'Sukabumi', 'Tasikmalaya'],
    'Banten': ['Serang', 'Tangerang', 'Tangerang Selatan', 'Cilegon'],
    'Jawa Tengah': ['Semarang', 'Surakarta', 'Magelang', 'Pekalongan', 'Salatiga', 'Tegal'],
    'DI Yogyakarta': ['Yogyakarta', 'Sleman', 'Bantul', 'Kulon Progo', 'Gunungkidul'],
    'Jawa Timur': ['Surabaya', 'Malang', 'Kediri', 'Madiun', 'Mojokerto', 'Pasuruan', 'Probolinggo', 'Batu', 'Blitar'],
    'Bali': ['Denpasar', 'Badung', 'Gianyar', 'Ubud', 'Tabanan', 'Karangasem', 'Buleleng'],
    'Nusa Tenggara Barat': ['Mataram', 'Bima'],
    'Nusa Tenggara Timur': ['Kupang'],
    'Kalimantan Barat': ['Pontianak', 'Singkawang'],
    'Kalimantan Tengah': ['Palangka Raya'],
    'Kalimantan Selatan': ['Banjarmasin', 'Banjarbaru'],
    'Kalimantan Timur': ['Samarinda', 'Balikpapan', 'Bontang'],
    'Kalimantan Utara': ['Tarakan'],
    'Sulawesi Utara': ['Manado', 'Bitung', 'Tomohon', 'Kotamobagu'],
    'Gorontalo': ['Gorontalo'],
    'Sulawesi Tengah': ['Palu'],
    'Sulawesi Barat': ['Mamuju'],
    'Sulawesi Selatan': ['Makassar', 'Parepare', 'Palopo'],
    'Sulawesi Tenggara': ['Kendari', 'Baubau'],
    'Maluku': ['Ambon', 'Tual'],
    'Maluku Utara': ['Ternate', 'Tidore Kepulauan'],
    'Papua': ['Jayapura'],
    'Papua Barat': ['Manokwari', 'Sorong'],
    'Papua Barat Daya': ['Sorong'],
    'Papua Tengah': ['Nabire'],
    'Papua Pegunungan': ['Wamena'],
    'Papua Selatan': ['Merauke'],
  };

  static List<String> get provinces => data.keys.toList();
  static List<String> citiesOf(String province) => data[province] ?? const [];
}

import 'package:supabase/supabase.dart';

void main() async {
  print("Mengecek daftar akun Arsitek yang terdaftar...");
  const url = 'https://eboseqlzrfabtiurwjpl.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVib3NlcWx6cmZhYnRpdXJ3anBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2ODMyOTUsImV4cCI6MjA5MjI1OTI5NX0.gUiVQ7RZAmLRlUFJ71LldgYOGmxU5VTdZqSI87jjLxo';

  final client = SupabaseClient(url, anonKey);
  try {
    final res = await client.from('profiles').select().eq('role', 'architect');
    if (res.isEmpty) {
      print("Tidak ada akun arsitek yang ditemukan.");
    } else {
      print("Ditemukan ${res.length} akun arsitek:");
      for (var i = 0; i < res.length; i++) {
        final row = res[i];
        print("${i + 1}. Nama: ${row['name']} | Phone: ${row['phone']} | ID: ${row['id']}");
      }
    }
  } catch (e) {
    print("Error: $e");
  }
}

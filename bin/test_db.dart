import 'package:supabase/supabase.dart';

void main() async {
  print("Memulai koneksi SupabaseClient murni...");
  const url = 'https://eboseqlzrfabtiurwjpl.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVib3NlcWx6cmZhYnRpdXJ3anBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2ODMyOTUsImV4cCI6MjA5MjI1OTI5NX0.gUiVQ7RZAmLRlUFJ71LldgYOGmxU5VTdZqSI87jjLxo';

  final client = SupabaseClient(url, anonKey);

  print("\n--- MENGECEK PROFIL TERBARU ---");
  try {
    final res = await client.from('profiles').select().order('created_at', ascending: false).limit(5);
    if (res.isNotEmpty) {
      for (var p in res) {
        print("Profile: ID=${p['id']}, Nama=${p['name']}, Role=${p['role']}, Created=${p['created_at']}, Verified=${p['is_verified']}");
      }
    } else {
      print("Tabel 'profiles' kosong.");
    }
  } catch (e) {
    print("Gagal membaca profiles: $e");
  }

  print("\n--- Selesai mengecek. ---");
}

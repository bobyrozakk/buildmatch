import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  // 🔥 GANTI INI BUAT TEST 2 USER
  String get currentUser {
    final user = supabase.auth.currentUser;
    return user?.id ?? "web_user";
  }

  // 📥 STREAM REALTIME MESSAGES
  Stream<List<Map<String, dynamic>>> getMessages() {
    const otherUser = "user_2";

    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((messages) {
          return messages.where((msg) {
            final sender = msg['user_id'];
            final receiver = msg['receiver_id'];

            return (sender == currentUser && receiver == otherUser) ||
                (sender == otherUser && receiver == currentUser);
          }).toList();
        });
  }

  // 📤 KIRIM PESAN
  Future<void> sendMessage() async {
    const otherUser = "user_2";

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await supabase.from('messages').insert({
      'user_id': currentUser,
      'receiver_id': otherUser,
      'text': text,
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat BuildMatch"), centerTitle: true),
      body: Column(
        children: [
          // 🔥 LIST CHAT
          Expanded(
            child: StreamBuilder(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(child: Text("Belum ada chat"));
                }

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['user_id'] == currentUser;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ✏️ INPUT + BUTTON
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ketik pesan...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

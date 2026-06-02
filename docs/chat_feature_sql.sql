-- =========================================================
-- BUILDMATCH: SQL Setup untuk Chat Feature
-- Jalankan di Supabase SQL Editor (Dashboard > SQL Editor)
-- =========================================================

-- 1. Tambah kolom 'status' ke tabel chats
--    'pending' = menunggu diterima arsitek
--    'accepted' = sudah diterima, bisa chat
ALTER TABLE public.chats 
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending';

-- 2. Semua chat yang sudah ada → jadikan 'accepted' (tidak merusak data lama)
UPDATE public.chats SET status = 'accepted' WHERE status = 'pending';

-- 3. ENABLE REALTIME pada tabel messages dan chats
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;

-- 4. RLS POLICY untuk tabel chats
-- Pastikan user bisa membaca chat mereka
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'chats' AND policyname = 'Users can see their own chats'
  ) THEN
    CREATE POLICY "Users can see their own chats"
      ON public.chats FOR SELECT
      USING (auth.uid() = client_id OR auth.uid() = vendor_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'chats' AND policyname = 'Users can create chats'
  ) THEN
    CREATE POLICY "Users can create chats"
      ON public.chats FOR INSERT
      WITH CHECK (auth.uid() = client_id OR auth.uid() = vendor_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'chats' AND policyname = 'Users can update their own chats'
  ) THEN
    CREATE POLICY "Users can update their own chats"
      ON public.chats FOR UPDATE
      USING (auth.uid() = client_id OR auth.uid() = vendor_id);
  END IF;
END $$;

-- 5. RLS POLICY untuk tabel messages
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can read messages in their chats'
  ) THEN
    CREATE POLICY "Users can read messages in their chats"
      ON public.messages FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM public.chats
          WHERE chats.id = messages.chat_id
          AND (chats.client_id = auth.uid() OR chats.vendor_id = auth.uid())
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can send messages in their chats'
  ) THEN
    CREATE POLICY "Users can send messages in their chats"
      ON public.messages FOR INSERT
      WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
          SELECT 1 FROM public.chats
          WHERE chats.id = messages.chat_id
          AND (chats.client_id = auth.uid() OR chats.vendor_id = auth.uid())
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can mark messages as read'
  ) THEN
    CREATE POLICY "Users can mark messages as read"
      ON public.messages FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM public.chats
          WHERE chats.id = messages.chat_id
          AND (chats.client_id = auth.uid() OR chats.vendor_id = auth.uid())
        )
      );
  END IF;
END $$;

-- 6. Buat tabel notifications jika belum ada
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type text DEFAULT 'general',
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can see their own notifications'
  ) THEN
    CREATE POLICY "Users can see their own notifications"
      ON public.notifications FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Allow notification insert'
  ) THEN
    CREATE POLICY "Allow notification insert"
      ON public.notifications FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

-- =========================================================
-- SELESAI. Jalankan: flutter run
-- =========================================================

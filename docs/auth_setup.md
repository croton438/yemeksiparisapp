# Supabase Auth setup

1. Copy `.env.sample` to `.env` and fill `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
2. Ensure `profiles`, `addresses`, `orders` migrations are applied to your Supabase project (use the SQL files in `supabase/migrations/`).
   - `supabase db push` or run the SQL via Supabase SQL Editor.
3. In Supabase Auth > Settings, enable Email OTP or Magic Link depending on your preference.
4. RLS policies are included in the SQL files; ensure they are applied.

Notes:
- The app uses `AuthStore` (ChangeNotifier) to listen to auth state and upsert profiles on first login.
- Login flow sends an email (OTP or magic link depending on your Supabase project). If using OTP, enter the code on the OTP screen.

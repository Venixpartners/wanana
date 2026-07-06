# Migrations

Applied to the production Supabase project via the Supabase connector.
Kept here as the source-of-truth record of schema changes.

- 2026-07-06 `supabase_auth_profiles_and_rpcs` — links profiles to auth.users,
  adds auth-based RPCs (profile_setup, me, my_calls, call_place, market_create,
  comment_add, wallet_top_up), grants execute to authenticated only.
- 2026-07-06 `retire_legacy_token_rpcs` — revokes API access to the old
  token-based demo RPCs replaced by Supabase Auth.

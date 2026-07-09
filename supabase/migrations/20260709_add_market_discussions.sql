-- Migration record: market discussions + support chatbot
-- Applied to production via Supabase MCP on 2026-07-09 as three migrations:
--   add_market_discussions_and_support
--   discussion_rpc_functions (+ drop_legacy_comment_add)
--   audit_actions_add_moderation
-- Demo credits only (NGN_DEMO). No real-money paths touched.

-- ============ Schema ============

alter table public.comments
  add column if not exists profile_id uuid references public.profiles(id),
  add column if not exists parent_id bigint references public.comments(id) on delete cascade,
  add column if not exists status text not null default 'visible',
  add column if not exists like_count integer not null default 0,
  add column if not exists reviewed boolean not null default false,
  add column if not exists moderated_by text,
  add column if not exists moderated_at timestamptz,
  add column if not exists moderation_reason text;

-- status check: visible | hidden | removed
-- comment_reactions: (comment_id, profile_id) pk — one like per user
-- comment_reports: unique (comment_id, reporter_profile_id), status open|reviewed
-- market_follows: (market_id, profile_id) pk
-- admin_pinned_updates: body 1..500 chars, active flag
-- chatbot_logs: topic key only — no user id, no message text (privacy-safe)
-- markets.comment_count: trigger-maintained count of visible comments

-- ============ Security ============
-- RLS enabled on all new tables with NO public policies; all privileges
-- revoked from anon/authenticated. Every read/write flows through
-- SECURITY DEFINER RPCs with set search_path='public'.
-- comments select policy tightened to status='visible' only.
-- audit_logs action whitelist extended with:
--   'comment_moderation', 'pinned_update'

-- ============ RPCs ============
-- market_comments(p_market_id)                      panel payload: comments, likes, oracle badge, pinned, follows
-- comment_add(p_market_id, p_body, p_parent_id)     prohibited-term screen + 15s rate limit
-- comment_like_toggle(p_comment_id)
-- comment_report(p_comment_id, p_reason)            reports visible to admins only
-- comment_delete_own(p_comment_id)
-- market_follow_toggle(p_market_id)
-- admin_comments_recent()                           queue with report reasons
-- admin_comment_moderate(id, action, reason)        hide/remove/restore/review — audited
-- admin_pin_update(market_id, body)                 audited
-- admin_unpin_update(id)                            audited
-- chatbot_log_topic(topic)                          topic key only

-- Full function bodies live in the Supabase migration history
-- (Dashboard -> Database -> Migrations).

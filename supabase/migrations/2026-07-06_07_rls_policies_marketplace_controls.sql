-- MILESTONE: RLS policies for marketplace controls
-- STATUS: PENDING APPLICATION (Supabase connector dropped mid-migration).
-- Apply via the Supabase connector when reconnected, or paste this whole file
-- into Supabase Dashboard -> SQL Editor -> Run.
-- Principle: direct table access is read-only and scoped to the caller.
-- All writes go through security-definer RPCs (ledger-gated, audited).

do $$
declare p record;
begin
  for p in select schemaname, tablename, policyname from pg_policies
    where schemaname = 'public'
      and tablename in ('profiles','markets','calls','comments','wallet_ledger','disputes','audit_logs')
  loop
    execute format('drop policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
  end loop;
end $$;

create policy profiles_select_own on public.profiles
  for select to authenticated
  using (user_id = auth.uid());

create policy markets_select_public on public.markets
  for select to anon, authenticated
  using (status in ('live','closed','in_verification','dispute_window','settled'));

create policy calls_select_own on public.calls
  for select to authenticated
  using (profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy comments_select_public on public.comments
  for select to anon, authenticated
  using (market_id in (select id from public.markets
                       where status in ('live','closed','in_verification','dispute_window','settled')));

create policy wallet_ledger_select_own on public.wallet_ledger
  for select to authenticated
  using (profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy disputes_select_own on public.disputes
  for select to authenticated
  using (profile_id in (select id from public.profiles where user_id = auth.uid()));

-- audit_logs: intentionally no policies -> invisible to the API;
-- admins read exclusively through admin_audit_recent()

revoke insert, update, delete on public.profiles, public.markets, public.calls,
  public.comments, public.wallet_ledger, public.disputes, public.audit_logs
  from anon, authenticated;

-- FIX: my_calls must return market_id (the dispute button needs it)
create or replace function public.my_calls()
returns json language plpgsql security definer set search_path to 'public'
as $$
declare v profiles;
begin
  select * into v from profiles where user_id = auth.uid();
  if v.id is null then return '[]'::json; end if;
  return coalesce((
    select json_agg(json_build_object(
      'id', c.id, 'market_id', c.market_id, 'side', c.side, 'amount', c.amount, 'created_at', c.created_at,
      'question', m.question, 'category', m.category, 'ends_on', m.ends_on,
      'yes_pool', m.yes_pool, 'no_pool', m.no_pool, 'status', m.status, 'outcome', m.outcome
    ) order by c.created_at desc)
    from calls c join markets m on m.id = c.market_id
    where c.profile_id = v.id
  ), '[]'::json);
end $$;

# wanana

**Africa argues about everything. Wanana pays whoever is right.**

Wanana is a peer prediction marketplace and skill-based social prediction game built for Africa. Users create real-world yes/no questions, the crowd makes calls, and users who call correctly share the pool after the outcome is verified.

Wanana is a game of skill. It is not sports betting, bookmaking, a casino, or gambling, and it never hosts forex, stock, crypto, securities, or investment markets.

## Architecture

| Layer | Service |
|---|---|
| Frontend (mobile web) | Vercel — static site served from `public/` |
| Domain | `www.wanana.africa` (GoDaddy → Vercel) |
| Database & API | Supabase (Postgres + RPC, RLS enabled) |
| Auth | Supabase Auth (email OTP / magic links — in progress) |
| Edge functions | Supabase Edge Functions |
| Email | Resend via custom SMTP (planned) |
| Payments | Paystack / Flutterwave placeholders only — no live money until licensing, KYC/AML, and audit controls are complete |

## Repository layout

```
public/
  index.html        # Full mobile web app (single file, no build step)
  manifest.json     # PWA manifest
  brand/            # Official logo assets — do not modify or re-typeset
supabase/
  functions/app/    # Temporary demo edge function (mirrors public/index.html)
vercel.json         # Vercel static deployment config
```

## Brand rules

Use the official wordmark exactly as supplied: lowercase, white/light on dark, only the middle "a" in orange. Never redesign, re-typeset, recolour, or add effects. Palette: Night Indigo `#0B0E31`, card `#141A47`, Wanana Orange `#FF7A1A` (single accent), Teal `#2DD4BF` (YES), Coral `#FB7185` (NO). Type: Space Grotesk (display) + Inter (body).

## Language rules

Say: call, make your call, pool, market, verified outcome, dispute window, Oracle, settled pool, game of skill.
Never say: bet, wager, bet slip, bookmaker, casino, gambling, payout odds.

## Environment variables (names only — never commit values)

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
RESEND_API_KEY=
RESEND_FROM_EMAIL=
RESEND_REPLY_TO_EMAIL=
NEXT_PUBLIC_APP_URL=
```

Responsible play: 18+ only. Play within your limit.

## Release notes: Public Demo MVP (7 July 2026)

**What was fixed.** Admin dashboard tabs (Markets, Disputes, Ledger, Users, Comments, Audit log) did not respond to clicks. Root cause: when the app was wrapped in a loader function (the CDN-blocker fix), the state object `S` and `render()` stopped being globals, so every inline `onclick` referencing them threw a silent ReferenceError. This also silently broke home category chips, sheet background-close, the Deposit/Withdraw buttons and the Help buttons. Fix: `window.S`, `window.render` and `window.setMsg` are now exposed; an empty state was added to the Audit tab. All six tabs re-tested with data and with empty states; active-tab highlighting confirmed.

**Files changed.** `public/index.html` (the fix), `README.md`, `.env.example` (new, names only).

**Supabase SQL added/changed.** None for this fix. All migrations in `supabase/migrations/` are already applied to production; the folder is the historical record.

**Upload to GitHub.** Replace the repository contents with this folder's contents (or upload the changed files only: `public/index.html`, `README.md`, `.env.example`). Commit message: `Fix admin dashboard tab navigation`.

**Run in Supabase.** Nothing. The live database is current.

**Environment variables.** See `.env.example`. Secrets live only in Supabase Edge Function secrets and Auth SMTP settings, never in this repository.

**Manual tests for Paul.** After deploy, hard-refresh and: (1) open Admin and click all six tabs -- each loads and highlights; (2) tap a user in Users -- the audited detail sheet opens with KYC/role/wallet controls; (3) on Markets (home), tap a category chip -- the feed filters; (4) in Wallet, tap Deposit -- the demo-wallet placeholder sheet opens and closes on background tap; (5) tap Help & FAQ from the wallet note.

// Wanana notification sender.
// Drains the notifications outbox via Resend. Safe to call anytime:
// without RESEND_API_KEY configured it reports status and sends nothing.
const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const FROM = Deno.env.get("RESEND_FROM_EMAIL") ?? "Wanana <no-reply@wanana.africa>";

const H = {
  "apikey": SERVICE_KEY,
  "Authorization": `Bearer ${SERVICE_KEY}`,
  "Content-Type": "application/json",
};

async function queuedCount(): Promise<number> {
  const r = await fetch(`${SB_URL}/rest/v1/notifications?select=id&status=eq.queued`, {
    headers: { ...H, "Prefer": "count=exact", "Range": "0-0" },
  });
  const range = r.headers.get("content-range") ?? "/0";
  return parseInt(range.split("/")[1] ?? "0", 10) || 0;
}

Deno.serve(async () => {
  if (!RESEND_KEY) {
    const queued = await queuedCount();
    return Response.json({ configured: false, queued,
      note: "Set RESEND_API_KEY (and optionally RESEND_FROM_EMAIL) in Edge Function secrets to enable sending." });
  }

  const claim = await fetch(`${SB_URL}/rest/v1/rpc/notify_claim_batch`, {
    method: "POST", headers: H, body: JSON.stringify({ p_limit: 20 }),
  });
  const batch: Array<{ id: number; email: string; subject: string; body_html: string }> =
    claim.ok ? await claim.json() : [];

  let sent = 0, failed = 0;
  for (const n of batch) {
    try {
      const r = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { "Authorization": `Bearer ${RESEND_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({ from: FROM, to: n.email, subject: n.subject, html: n.body_html }),
      });
      if (!r.ok) throw new Error(`Resend ${r.status}: ${(await r.text()).slice(0, 300)}`);
      sent++;
    } catch (e) {
      failed++;
      await fetch(`${SB_URL}/rest/v1/notifications?id=eq.${n.id}`, {
        method: "PATCH", headers: H,
        body: JSON.stringify({ status: "failed", error: String(e).slice(0, 500) }),
      });
    }
  }
  return Response.json({ configured: true, sent, failed, remaining: await queuedCount() });
});

// Temporary demo edge function.
// Serves the Wanana mobile web app (mirror of /public/index.html with the
// wordmark inlined from logo.b64). Production frontend lives on Vercel.
const rawHtml = await Deno.readTextFile(new URL("./app.html", import.meta.url));
const logoB64 = (await Deno.readTextFile(new URL("./logo.b64", import.meta.url))).trim();
const html = rawHtml.replaceAll("__WORDMARK_B64__", logoB64);
Deno.serve(() =>
  new Response(html, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=60",
    },
  })
);

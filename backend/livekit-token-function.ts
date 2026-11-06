// VibeLive — livekit-token Edge Function (Supabase Deno)
// Purpose: issue short-lived LiveKit access tokens ONLY to authenticated
// Supabase users who are allowed into the requested room.
// Secrets (set in Supabase Edge Functions > Secrets, never in client code):
//   LIVEKIT_API_KEY, LIVEKIT_API_SECRET, LIVEKIT_URL (wss://...)
// Built-in Supabase env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  let bin = "";
  bytes.forEach((b) => (bin += String.fromCharCode(b)));
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function livekitJwt(apiKey: string, apiSecret: string, identity: string,
                          name: string, room: string, canPublish: boolean): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "HS256", typ: "JWT" };
  const payload = {
    iss: apiKey, sub: identity, name, iat: now, nbf: now, exp: now + 60 * 60, // 1 hour
    video: { roomJoin: true, room, canPublish, canSubscribe: true, canPublishData: true },
  };
  const signingInput = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`;
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(apiSecret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(signingInput));
  return `${signingInput}.${b64url(new Uint8Array(sig))}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } });
    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) return json({ error: "not_authenticated" }, 401);

    const { stream_id, mode } = await req.json();
    if (!stream_id || !["host", "viewer"].includes(mode))
      return json({ error: "bad_request" }, 400);

    // Permission check against real data (service role bypasses RLS for the check only)
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { data: stream } = await admin.from("streams")
      .select("id, host_id, livekit_room, status").eq("id", stream_id).single();
    if (!stream) return json({ error: "stream_not_found" }, 404);

    let canPublish = false;
    if (mode === "host") {
      if (stream.host_id !== user.id) return json({ error: "not_the_host" }, 403);
      if (stream.status !== "live") return json({ error: "stream_not_live" }, 403);
      canPublish = true;
    } else {
      if (stream.status !== "live") return json({ error: "stream_not_live" }, 403);
      const { data: blocked } = await admin.from("blocks").select("blocker_id")
        .or(`and(blocker_id.eq.${stream.host_id},blocked_id.eq.${user.id}),and(blocker_id.eq.${user.id},blocked_id.eq.${stream.host_id})`)
        .limit(1);
      if (blocked && blocked.length > 0) return json({ error: "blocked" }, 403);
    }

    const { data: profile } = await admin.from("profiles")
      .select("username, display_name").eq("id", user.id).single();
    const name = profile?.display_name || profile?.username || "VibeLive user";

    const token = await livekitJwt(
      Deno.env.get("LIVEKIT_API_KEY")!, Deno.env.get("LIVEKIT_API_SECRET")!,
      user.id, name, stream.livekit_room, canPublish);
    return json({ token, url: Deno.env.get("LIVEKIT_URL"), room: stream.livekit_room, canPublish });
  } catch (e) {
    return json({ error: "server_error", detail: String(e) }, 500);
  }
  function json(body: unknown, status = 200) {
    return new Response(JSON.stringify(body),
      { status, headers: { ...cors, "Content-Type": "application/json" } });
  }
});

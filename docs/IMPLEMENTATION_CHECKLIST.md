# VibeLive — Implementation Checklist
Updated: 2026-10-21 (America/Vancouver). Statuses are honest: nothing moves to
"tested" without an actual test.

## Completed and tested
- Existing app inspected: static single-file prototype, no backend (confirmed from source + render).
- Supabase account created in Shelley's name (no card/payment ever requested).
- Supabase project "VibeLive" created, Free plan (Nano), status Healthy, Data API enabled/reachable.
- LiveKit account verified; project "VibeLive" created, Build plan, billing page shows NEXT INVOICE $0.00,
  API keys page reachable. It is the only project in that account (separate from OpenCircle).
- Free-tier limits for both services checked against sources citing official pricing pages.

## Implemented but not fully tested
- The rebuilt VibeLive app (web artifact "VibeLive"): real signup/login + email-confirmation
  handling, editable profiles with avatar/cover uploads, Home (real live streams + posts with
  create/like/comment), people search, follow/block/report, private messaging (realtime,
  unread counts), wallet (real balance + history), gifts via send_gift RPC, Go Live with
  camera preview + 9 filters + beauty sliders, stream chat, real participant list wiring,
  Quick Exit incl. auto-hide on backgrounding. Build + automated audit passed and the backend
  was probed live (Auth healthy, RLS denying anonymous reads as designed) — BUT the signed-in
  flows have not yet been exercised end-to-end with a real account; that is the next test.
- LiveKit streaming wiring in the app: built; the livekit-token function is now deployed
  (below), so connections should work — the first real two-account stream test is still
  to be run.
- livekit-token Edge Function: DEPLOYED + VERIFIED 2026-10-22. Unauthenticated GET →
  gateway auth rejection (not 404); POST with a public non-user token → HTTP 401
  {"error":"not_authenticated"} from the function's own code. Authenticated token
  issuance (real user + live stream) not yet exercised — part of the first stream test.

## Also completed and tested (database stage, 2026-10-21)
- Schema APPLIED in Supabase: run reported "Success. No rows returned", zero errors.
  All 17 tables verified in the Table Editor; RLS verified enabled on all 17 with the
  expected policies (incl. read-own-only on wallets / coin_transactions / gift_transactions).
- Storage buckets avatars, covers, post-media created (public).
- Auth state verified read-only: Email provider ENABLED, Confirm email ON, new signups ON,
  phone/OAuth providers disabled. Nothing changed.
- LiveKit token Edge Function code written (auth required, host/viewer permission checks,
  blocked check, 1-hour tokens, secret only in server env). Not deployed yet.

## Not yet implemented
- Supabase Auth configuration check + app connection (public anon key only in client).
- Server-side LiveKit token function (Edge Function holding the LiveKit secret; client never sees it).
- App rebuild: demo users/conversations/viewer counts/local coins removed; real signup/login/profile.
- Real private messaging in the app.
- Real multi-device livestreaming in the app: join/leave, real viewer list (clickable), Quick Exit,
  camera/mic controls, reconnection.
- Gifts in the app wired to send_gift() with premium artwork/animations/sounds; coin purchases
  (Google Play Billing belongs to the Android stage — not in the web tester build).
- Moderation UI (report/block flows exist in the database; app screens not built yet).
- Feed/posts/communities UI (tables exist; screens not built yet).
- Android packaging (VibeLive-only package ID), signed .aab, real-device testing.
- Google Play readiness: NOT ready — will not be claimed until the Android build + real-device tests pass.

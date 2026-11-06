# VibeLive - your code, all of it

This is everything Harbor built for VibeLive, so you can take it anywhere.

## What is in here

- `vibelive-web.html` - the whole VibeLive app in one file. Sign in, profiles,
  home feed, messages, wallet, gifts, Go Live with camera and filters, stream
  room, Quick Exit. This is the same code inside the Android app.
- `android-project/` - the Android app project (Capacitor). This is also in your
  GitHub repo at https://github.com/chkymnky74-a11y/vibelive-android
  It builds with GitHub Actions (see `.github/workflows/android.yml`).
- `backend-and-docs/` - the Supabase database setup (vibelive-schema.sql,
  vibelive-storage-policies.sql, vibelive-grants-fix.sql), the LiveKit token
  function (livekit-token-function.ts), the build checklist, the Android Play
  prep notes, the prize wheel preview, and your full vision spec
  (VibeLive-Vision-Spec.md).

## Your project details (public, safe to share)

- Supabase project: "VibeLive", ref iqrefsaqtxoynzkhlfed,
  URL https://iqrefsaqtxoynzkhlfed.supabase.co
- LiveKit project: "VibeLive", URL vibelive-fvzu5m96.livekit.cloud
- Android package ID: com.shelleywrites.vibelive, version 0.1.0, versionCode 1
- Your VibeLive account: chkymnky74 (signed up, email confirmed)
- GitHub repo: https://github.com/chkymnky74-a11y/vibelive-android
- Debug APK direct link:
  https://raw.githubusercontent.com/chkymnky74-a11y/vibelive-android/main/releases/app-debug.apk

## Secrets - NOT in this package (on purpose)

These were never written down anywhere, so they are not in these files. They
live in your own dashboards. Whoever helps you next will need them from there:

- Supabase service_role key: Supabase dashboard, VibeLive project, Settings,
  API. Never put it in app code. It is only for server side use.
- LiveKit API secret: LiveKit dashboard, VibeLive project, Settings, API Keys.
  It lives in Supabase as a server secret for the livekit-token function.
- Supabase database password: set when the project was made. Reset it in the
  Supabase dashboard if it is lost.
- Gmail app password for VibeLive emails: your Google account, Security,
  App passwords, named VibeLive. It is stored in Supabase SMTP settings.

The only key inside the code is the Supabase publishable key. That one is
meant to be public and is safe in the app.

## What is still to do

- The release AAB is unsigned. It needs an upload keystore made and the AAB
  signed before it can go into Play Console.
- The email confirmation link still points to localhost. Once the web app has
  a public address, the Supabase Site URL has to be changed to that address.
- The gifts, prize wheel and clips are previews. They are not wired into the
  app yet.

## Gifts

- `gift-animation-preview.html` - the gift codes. All 42 gifts in 6 families
  with the animations and sounds, including the receiver name spoken and
  shown in lights for Legends and Cosmic gifts. Open it in a browser to see
  them play.
- `gift-clips/` - the finished animated gift clips, clean names, ready to
  send: the 4 Legends, Pride gifts, funny and cute gifts, holidays, social
  gifts, Vince the Bouncer scenes, the majestic Scorpio, birthday, disco
  palace and golden duck.
- The prize wheel preview is in `backend-and-docs/prize-wheel-preview.html`.

# VibeLive Android — cloud build

This folder is everything GitHub needs to build the VibeLive Android app
for free in the cloud. It exists because the build cannot run on the local
machine: the local machine blocks the tool Gradle needs to talk to itself.

## What it does

When this code is put on GitHub, GitHub Actions runs the workflow in
`.github/workflows/android.yml`. That workflow:

1. Sets up Node 24, Java 17, and the Android SDK (all free).
2. Installs the app's packages and syncs the web app into the Android project.
3. Builds two files:
   - a debug APK (for installing straight on a phone to test), and
   - an unsigned release AAB (the file Google Play Console wants).
4. Saves both files as downloadable build artifacts.

The app inside is the real VibeLive web app, package name
`com.shelleywrites.vibelive`, version 0.1.0. Only the public Supabase
publishable key is in it. No passwords, no secret keys, nothing private.

## Cost

Free. GitHub Actions is free for public repos with no minute limit, and
this small build is far inside the free allowance even if the repo is
private (2,000 free minutes a month; this build takes only a few minutes).
If that ever changes, this file will say so before anything is spent.

## The one step left (needs Shelley)

Nothing here is on GitHub yet, and no GitHub account is connected from
this machine. The one step is:

1. Shelley signs in to GitHub (free account, github.com) and creates a
   new repo, for example called `vibelive-android`.
2. The contents of this folder are pushed to that repo.
3. The Actions run starts on its own. When it finishes green, download
   the `vibelive-release-aab-unsigned` artifact from the run page.

## After the AAB exists (a later secure step, not part of this build)

The AAB is unsigned on purpose. Before it goes to Play Console it must
be signed with an upload keystore, created once with keytool, with the
password kept private and backed up. Losing the keystore means a new app.
That step happens separately, never in this folder or in chat.

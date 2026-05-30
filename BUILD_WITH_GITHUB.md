# 📱 Build PitStock with GitHub Actions (free, phone-only)

GitHub compiles the APK for you in the cloud every time you upload code.
No PC, no Codemagic account needed.

## What you need
- An Android phone with a browser
- A free GitHub account
- The `pitstock` project files

---

## STEP 1 — Create a GitHub account & repo
1. Go to https://github.com → Sign up (free), verify email.
2. Tap **+** (top right) → **New repository**.
3. Name it `pitstock`. Private or Public is fine.
4. Tap **Create repository**.

## STEP 2 — Upload the code
1. Download the `pitstock` folder from your workspace as a ZIP to your phone.
2. Unzip it (e.g. with ZArchiver or Files by Google).
3. In your browser, open your repo. Tip: enable **"Desktop site"** in the browser
   menu — the upload page is easier that way.
4. **Add file → Upload files** → select all files & folders → **Commit changes**.
5. ⚠️ These must be at the repo ROOT (not inside an extra `pitstock/` subfolder):
   - `pubspec.yaml`
   - `lib/`
   - `android/`
   - `assets/`
   - `.github/workflows/build.yml`   ← the build recipe (already included)

   IMPORTANT: folders starting with a dot (like `.github`) can be hidden in some
   file apps. Make sure `.github/workflows/build.yml` actually uploaded — open the
   repo and confirm you see a `.github` folder. If it didn't upload, create it
   manually: **Add file → Create new file**, type the path
   `.github/workflows/build.yml`, paste the file contents, and commit.

## STEP 3 — Run the build
The build starts automatically after you upload. To watch or re-run it:
1. Open your repo → **Actions** tab.
2. You'll see a run called **"Build PitStock APK"**.
   - If it's not running, click the workflow on the left → **Run workflow**.
3. Wait ~10–15 minutes for the green ✅.

## STEP 4 — Download & install the APK
1. Open the finished (green ✅) run.
2. Scroll to the **Artifacts** section at the bottom.
3. Download **`pitstock-release-apk`** (a .zip) → unzip → you get
   `app-release.apk`.
4. Tap the APK → allow "install from unknown sources" if asked → Install.
5. Open **PitStock**, log in with PIN **1111** (Owner).

---

## Updating the app later
Any time you change code and upload it to GitHub, a new APK builds automatically.
Just grab the latest artifact from the **Actions** tab.

## If a build fails
1. Open the failed run → click the red step → read the error.
2. Common fix — package version conflict: edit `.github/workflows/build.yml`,
   change `flutter pub get` to `flutter pub upgrade --major-versions`, commit.
3. Send the error text to your assistant for the exact fix.

## Notes
- GitHub Actions is free for public repos and includes a generous free monthly
  quota for private repos — plenty for this.
- This is the FIRST real compile of the code, so a small fix-up may surface on
  the first run. Paste the log line to your assistant if so.

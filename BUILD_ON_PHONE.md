# 📱 Build PitStock using only your Android phone (Codemagic)

No computer needed. A cloud server compiles the app and gives you an APK to install.

## What you need
- An Android phone with a browser
- A free GitHub account
- A free Codemagic account
- The `pitstock` project files

---

## PART 1 — Put the code on GitHub

1. Create an account at https://github.com
2. Create a new **repository** named `pitstock` (keep it Private if you want).
3. Upload the project:
   - Download the `pitstock` folder from your workspace as a ZIP to your phone.
   - Unzip it (use an app like ZArchiver if needed).
   - On github.com (use "Desktop site" in your browser menu for an easier layout):
     open your repo → **Add file → Upload files** → select all the files/folders
     → **Commit changes**.
   - ⚠️ Make sure these stay in the repo root: `pubspec.yaml`, `lib/`,
     `android/`, `assets/`, and `codemagic.yaml`.

---

## PART 2 — Build on Codemagic

1. Go to https://codemagic.io on your phone → **Sign up with GitHub**.
2. Allow Codemagic to access your repositories.
3. Click **Add application** → choose the `pitstock` repo → select **Flutter App**.
4. Codemagic detects the included `codemagic.yaml` and the **PitStock Android APK**
   workflow. Select it.
5. Tap **Start new build** → pick the `android-apk` workflow → **Start build**.
6. Wait ~10–15 minutes.
7. When the build turns green ✅, scroll to **Artifacts** and download
   `app-release.apk` to your phone.

(Optional: edit `codemagic.yaml` and add your email under `recipients:` to get
the APK mailed to you automatically.)

---

## PART 3 — Install the APK

1. Tap the downloaded `app-release.apk`.
2. Android may warn about "unknown sources" → allow installation for your browser
   or Files app.
3. Open **PitStock** and log in with PIN **1111** (Owner).

---

## If a build fails
- Open the failed build log on Codemagic and read the red error.
- Most first-time issues are fixed automatically by the `flutter create` step in
  `codemagic.yaml`.
- A package version conflict? In `codemagic.yaml`, change
  `flutter pub get` to `flutter pub upgrade --major-versions`.
- Send the error text to your assistant for the exact fix.

## Free usage
Codemagic's free tier includes 500 build minutes/month — plenty for this app.

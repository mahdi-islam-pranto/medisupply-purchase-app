# Releasing Medi Purchase (Android)

App id: `com.medisupplybd.purchase` — permanent once uploaded to Google Play.

## 1. One-time: create the upload key

```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\medi-purchase-upload.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep the `.jks` file and its passwords safe (a password manager + a backup).
If it is lost, you can no longer update the app on Google Play.

## 2. One-time: point the build at the key

Create `android/key.properties` (already ignored by git — never commit it):

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
storeFile=C:\\Users\\<you>\\medi-purchase-upload.jks
```

Without this file, release builds are signed with the debug key: fine for
testing on a phone, but Google Play rejects them.

## 3. Each release

1. Raise the version in `pubspec.yaml`: `version: 1.0.1+2`
   (`1.0.1` is shown to users; `+2` must go up by one for every upload).
2. `flutter test`
3. Build:
   - Google Play: `flutter build appbundle --release`
     → `build/app/outputs/bundle/release/app-release.aab`
   - Direct install (WhatsApp / USB): `flutter build apk --release`
     → `build/app/outputs/flutter-apk/app-release.apk`

## Icon and splash

Source images live in `assets/icon/` (made from `assets/images/lon_icon.jpg`).
After replacing them, regenerate:

```powershell
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`splash_android12.png` keeps the badge inside the central circle, because
Android 12+ crops the launch icon to a circle.

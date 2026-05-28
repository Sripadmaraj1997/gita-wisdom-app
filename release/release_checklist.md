# Gita Wisdom MVP Release Checklist

## App Icon

- Source asset: `assets/branding/app_icon.png`
- Generated Android icons: `android/app/src/main/res/mipmap-*`
- Generated iOS icons: `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- Generated web icons: `web/icons`
- Generated macOS icons: `macos/Runner/Assets.xcassets/AppIcon.appiconset`

Regenerate after replacing the placeholder:

```sh
flutter pub run flutter_launcher_icons
```

## Splash

- Source asset: `assets/branding/splash_logo.png`
- Config: `pubspec.yaml`
- Generated web splash assets: `web/splash`
- Generated native splash assets: Android and iOS platform folders

Regenerate after replacing the placeholder:

```sh
flutter pub run flutter_native_splash:create
```

## Privacy Policy

- In-app route: Settings > Privacy Policy
- Markdown copy: `docs/privacy_policy.md`
- Web copy: `web/privacy_policy.html`

Publish the web policy at a public URL before submitting to App Store Connect or Google Play Console.

## Screenshots

Capture the required app screens listed in `release/screenshots/README.md`.

Suggested App Store Connect screenshots:

- iPhone 6.7": 1290 x 2796
- iPhone 6.5": 1242 x 2688

Suggested Google Play screenshots:

- Phone screenshots: 1080 x 1920 or higher
- Tablet screenshots if tablet support is enabled

## TestFlight Build

Before building:

- Open `ios/Runner.xcworkspace` in Xcode.
- Select the Runner target.
- Set Signing & Capabilities > Team to the Apple Developer team.
- Confirm a unique bundle ID.
- Let Xcode create or select a provisioning profile.

Build command:

```sh
flutter build ipa --release
```

Upload from Xcode Organizer or Transporter after the archive is signed.

## Android Internal Testing

Before building:

- Install Android Studio or Android command-line tools.
- Set `ANDROID_HOME` to the Android SDK path.
- Create a release signing keystore.
- Configure Android release signing before Play Console upload.

Build command:

```sh
flutter build appbundle --release
```

Upload the generated `.aab` to Google Play Console > Testing > Internal testing.

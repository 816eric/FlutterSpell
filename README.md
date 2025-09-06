# spell

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Run locally:
    local network access: flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8888
    current pc debug: flutter run -d chrome --web-hostname=127.0.0.1 --web-port=8888

build for web app:
    flutter build web
    cd build\web
    python -m http.server 8888 --bind 0.0.0.0

Web release and deployement:
    flutter build web --release   
    copy the web folder to https://dash.cloudflare.com/b4eb700e01a66453ef2d341ca0f6cce5/pages/view/spell


Build the APK
    flutter build apk --debug
    Profile APK (performance profiling):
    flutter build apk --profile
    Release APK (optimized for publishing):
    flutter build apk --release
    4. Find the APK
    After building, the file is located in:
    project_folder/build/app/outputs/flutter-apk/app-release.apk
    5. (Optional) Split APKs by ABI
    To reduce file size:
    flutter build apk --split-per-abi
    This generates separate APKs for each architecture (e.g., armeabi-v7a, arm64-v8a, x86_64).

    👉 If you plan to publish on the Play Store, you might want to build an App Bundle (AAB) 
    flutter build appbundle --release
    project_folder/build/app/outputs/bundle/release/app-release.aab
    Google Play requires .aab files for new apps.





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
    flutter run -d chrome --web-hostname=0.0.0.0 --web-port=888

build for web app:
    flutter build web
    cd build\web
    python -m http.server 8888 --bind 0.0.0.0

Web release and deployement:
    flutter build web --release   
    copy the web folder to https://dash.cloudflare.com/b4eb700e01a66453ef2d341ca0f6cce5/pages/view/spell



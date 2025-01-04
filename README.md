# fapp

A new Flutter project for practice

## Getting Started

This project is a starting point for a Flutter application.

`flutter create --org org.fictio --platforms android,ios --android-language java --ios-language objc fapp`

## Version

name | ver | url
--- | --- | ---
Flutter | 3.24.0 | https://docs.flutter.dev/release/archive
Dart | 3.5.0 | https://docs.flutter.dev/release/archive
Visual Studio | Visual Studio Community 2022 17.12.3 | https://visualstudio.microsoft.com/zh-hans/downloads/
Android Studio | 2023.3 | https://developer.android.com/studio/archive
xcode | 16.2 | https://developer.apple.com/cn/support/xcode/
cocoapods | 1.16.2 | -

## Env

cn proxy
```ini
# win
C:> $env:PUB_HOSTED_URL="https://pub.flutter-io.cn"  
C:> $env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"

# liunx/mac
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
```

## build
1. flutter pub get && flutter pub run flutter_launcher_icons:main
2. flutter build windows --release (can use `Inno Setup` to build installer)
3. flutter build apk --release
4. flutter build ipa --release

## Ref
1. [depend for install](https://docs.flutter.dev/get-started/install/windows/mobile)
2. [book: flutter_in_action_2nd](https://github.com/flutterchina/flutter_in_action_2nd)
3. [blog: flutter-study](https://github.com/yang7229693/flutter-study)



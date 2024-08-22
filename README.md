![Build Android workflow](https://github.com/breez/misty-breez/actions/workflows/build-android.yml/badge.svg)
![Build iOS workflow](https://github.com/breez/misty-breez/actions/workflows/build-ios.yml/badge.svg)
![CI workflow](https://github.com/breez/misty-breez/actions/workflows/CI.yml/badge.svg)

# Misty Breez

<img align="right" width="112" height="42" title="Breez logo"
src="./src/images/liquid-logo-color.svg">

Misty Breez is a migration of [Breez mobile app](https://github.com/breez/breezmobile) to
the [Breez Liquid SDK](https://github.com/breez/breez-sdk-liquid) infrastructure.

## Build

### Build the lightning_tookit plugin

Misty Breez depends on Breez Liquid SDK's [breez_liquid](https://github.com/breez/breez-sdk-liquid/tree/main/packages/dart) & [flutter_breez_liquid](https://github.com/breez/breez-sdk-liquid/tree/main/packages/flutter) plugin,
so be sure to follow those instructions first.

After successfully having build the `breez_liquid` & `flutter_breez_liquid` make sure that [breez-sdk-liquid](https://github.com/breez/breez-sdk-liquid)
and misty-breez are side by side like so:

```
breez-sdk-liquid/
├─ lib/
│  ├─ bindings/
│  ├─ core/
├─ packages/
│  ├─ dart/
│  ├─ flutter/
misty-breez/
├─ android/
├─ ios/

```

### Add Firebase configuration

FlutterFire CLI currently requires the official Firebase CLI to also be installed, see [Install the Firebase CLI](https://firebase.google.com/docs/cli#install_the_firebase_cli) for how to install it.

After installing Firebase CLI, log into Firebase using your Google account by running the following command:
```
firebase login
```
then, install the FlutterFire CLI by running the following command from any directory:
```
dart pub global activate flutterfire_cli
```

From Flutter project directory, run the following command to start the app configuration workflow:
```
flutterfire configure -p breez-technology -o lib/firebase/firebase_options.dart --platforms="android,ios" -a com.breez.liquid.l_breez -y
```

### Android

```
flutter build apk --target=lib/main/main.dart 
```

### iOS

```
flutter build ios --target=lib/main/main.dart 
```

## Run

```
flutter run --target=lib/main/main.dart 
```

___

## Contributors

### Pre-commit `dart format` with Lefthook

[Lefthook](https://github.com/evilmartians/lefthook) is a Git hooks manager that allows custom logic to be
executed prior to Git commit or push. Misty Breez comes with Lefthook configuration (`lefthook.yml`), but it must
be installed first.

### Installation

- Install Lefthook.
  See [installation guide](https://github.com/evilmartians/lefthook/blob/master/docs/install.md).
- Run the following command from project root folder to install hooks:

```sh
$ lefthook install
```

Before you commit your changes, Lefthook will automatically run `dart format`.

### Skipping hooks

Should the need arise to skip `pre-commit` hook, CLI users can use the standard Git option `--no-verify` to skip `pre-commit` hook:

```sh
$ git commit -m "..." --no-verify
```

There currently is no Github Desktop support to skip git-hooks. However, you can run:
```sh
$ lefthook uninstall
```
to clear hooks related to `lefthook.yml` configuration before committing your changes.

Do no forget to run `lefthook install` to re-activate `pre-commit` hook.

```sh
$ lefthook install
```

### Troubleshooting
For troubleshooting, please check the [troubleshooting.md](troubleshooting.md) file
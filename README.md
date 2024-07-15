![Build Android workflow](https://github.com/breez/l-breez/actions/workflows/build-android.yml/badge.svg)
![Build iOS workflow](https://github.com/breez/l-breez/actions/workflows/build-ios.yml/badge.svg)
![CI workflow](https://github.com/breez/l-breez/actions/workflows/CI.yml/badge.svg)

# l-Breez

<img align="right" width="112" height="42" title="Breez logo"
src="./src/images/liquid-logo-color.svg">

l-Breez is a migration of [Breez mobile app](https://github.com/breez/breezmobile) to
the [Breez Liquid SDK](https://github.com/breez/breez-sdk-liquid) infrastructure.

## Build

### Build the lightning_tookit plugin

l-Breez depends on Breez Liquid SDK's [breez_liquid](https://github.com/breez/breez-sdk-liquid/tree/main/packages/dart) & [flutter_breez_liquid](https://github.com/breez/breez-sdk-liquid/tree/main/packages/flutter) plugin,
so be sure to follow those instructions first.

After successfully having build the `breez_liquid` & `flutter_breez_liquid` make sure that [breez-sdk-liquid](https://github.com/breez/breez-sdk-liquid)
and l-breez are side by side like so:

```
breez-sdk-liquid/
├─ lib/
│  ├─ bindings/
│  ├─ core/
├─ packages/
│  ├─ dart/
│  ├─ flutter/
l-breez/
├─ android/
├─ ios/

```

### Add firebase config files
l-breez depends on google services and requires a configured firebase app.

To create your firebase app follow the following link
[create-firebase-project](https://firebase.google.com/docs/android/setup#create-firebase-project).

After creating the app follow the instructions to create the specific
configuration file for your platform:
* For android - place the google-services.json in the android/app folder
* For iOS - place the GoogleService-info.plist under ios/Runner folder

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
executed prior to Git commit or push. l-Breez comes with Lefthook configuration (`lefthook.yml`), but it must
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
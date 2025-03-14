![Build Android workflow](https://github.com/breez/misty-breez/actions/workflows/build-android.yml/badge.svg)
![Build iOS workflow](https://github.com/breez/misty-breez/actions/workflows/build-ios.yml/badge.svg)
![CI workflow](https://github.com/breez/misty-breez/actions/workflows/CI.yml/badge.svg)

# Misty Breez

Misty Breez is a mobile app built with Flutter that serves as a reference implementation for the [Breez SDK - Nodeless](https://sdk-doc-liquid.breez.technology/) that:
* Demonstrates the full capabilities of building with the SDK
* Showcases best practices for designing an intuitive UI and UX for self-custodial Lightning payments
* Offers a ready-made solution that can be white-labeled for partners looking to build a new app

## Features

- [x] **Sending payments** via various protocols such as: Bolt11, Bolt12, BIP353, LNURL-Pay, Lightning address, BTC address
- [x] **Receiving payments** via various protocols such as: Bolt11, LNURL-Withdraw, LNURL-Pay, Lightning address, BTC address
- [x] A built-in, customizable user@breez.fun Lightning address
- [x] Receive payments even when the app is offline (requires notifications)
- [x] Self-custodial: keys are only held by users
- [x] Free open-source software (ofc!)

## Installation 

#### Android 

[Latest APK](https://github.com/breez/misty-breez/releases/tag/v0.1.0-alpha)

#### iOS

[TestFlight](https://testflight.apple.com/join/z8ZN1V6c)

## For Developers

**Build the lightning_tookit plugin**

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

**Add Firebase configuration**

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

**Android**

```
flutter build apk --target=lib/main/main.dart 
```

**iOS**

```
flutter build ios --target=lib/main/main.dart 
```

**Run**

```
flutter run --target=lib/main/main.dart 
```

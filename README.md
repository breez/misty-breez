![Build Android workflow](https://github.com/breez/misty-breez/actions/workflows/build-android.yml/badge.svg)
![Build iOS workflow](https://github.com/breez/misty-breez/actions/workflows/build-ios.yml/badge.svg)
![CI workflow](https://github.com/breez/misty-breez/actions/workflows/CI.yml/badge.svg)

<img align="center" width="112" height="42" title="Breez logo"
src="./assets/images/liquid-logo-color.svg">

# Misty Breez

Misty Breez is a reference app built with the [Breez SDK - Nodeless](https://sdk-doc-liquid.breez.technology/), showcasing best practices for delivering a frictionless bitcoin payment experience — and is available to partners as a white-label solution.

The app demonstrates how to design intuitive UI and UX with the [Breez SDK](https://sdk-doc-liquid.breez.technology/), and offer end-users self-custodial Lightning payments — with no channels or setup fees — so they can send and receive bitcoin out-of-the-box.

Powered by a [nodeless Lightning implementation](https://sdk-doc-liquid.breez.technology/), Misty Breez is a ready-made solution for partners to offer bitcoin payments in their own branded apps.

## Core Functions

- **Sending payments** *via various protocols such as: Bolt11, Bolt12, LNURL-Pay, Lightning address, BIP353, BTC address.*
- **Receiving payments** *via various protocols such as: Bolt11, LNURL-Withdraw, BTC address.*
- **Interacting with the SDK ** *e.g. balance, max allow to pay, max allow to receive, refunds.*

## Key Features

- [x] Send and receive Lightning payments 
- [x] On-chain interoperability
- [x] LNURL functionality
- [x] Keys are only held by users
- [x] Open-source

## Installation 

### Android 

TBA

### iOS

TBA

## For Developers

### Build 
#### Build the lightning_tookit plugin

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

#### Add Firebase configuration

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

#### Android

```
flutter build apk --target=lib/main/main.dart 
```

#### iOS

```
flutter build ios --target=lib/main/main.dart 
```

### Run

```
flutter run --target=lib/main/main.dart 
```

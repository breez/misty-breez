# Setting up your Environment

## Build Dart & Flutter plugins of `Breez SDK - Nodeless`

Misty Breez depends on [flutter_breez_liquid](https://github.com/breez/breez-sdk-liquid/tree/main/packages/flutter_breez_liquid) plugin of [Breez SDK - Nodeless (Liquid Implementation)](https://sdk-doc-liquid.breez.technology/),
so be sure to follow those instructions first.

After successfully having built the `flutter_breez_liquid` make sure that [breez-sdk-liquid](https://github.com/breez/breez-sdk-liquid)
and `misty-breez` are side by side like so:

```
breez-sdk-liquid/
├─ lib/
│  ├─ bindings/
│  ├─ core/
├─ packages/
│  ├─ flutter_breez_liquid/
misty-breez/
├─ android/
├─ ios/

```

## Add Firebase configuration

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
flutterfire configure -p breez-technology -o lib/firebase/firebase_options.dart --platforms="android,ios" -a com.breez.misty -y
```

#### Android

```
flutter build apk --target=lib/main/main.dart 
```

#### iOS

```
flutter build ios --target=lib/main/main.dart 
```

#### Run

```
flutter run --target=lib/main/main.dart 
```

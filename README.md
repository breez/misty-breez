![Build Android workflow](https://github.com/breez/misty-breez/actions/workflows/build-android.yml/badge.svg)
![Build iOS workflow](https://github.com/breez/misty-breez/actions/workflows/build-ios.yml/badge.svg)
![CI workflow](https://github.com/breez/misty-breez/actions/workflows/CI.yml/badge.svg)

# Misty Breez

![Image](https://github.com/user-attachments/assets/e1b818c0-075b-4f2c-a71f-4b7970e5cd3c)

Lightning made easy!

Misty Breez is the simplest self-custodial app for sending and receiving Lightning payments. It's a Flutter mobile app that serves as a reference implementation for the [Breez SDK - Nodeless](https://sdk-doc-liquid.breez.technology/) to:
* Demonstrate the full capabilities of building with the SDK
* Showcase best practices for designing an intuitive UI and UX for self-custodial Lightning payments
* Offer a ready-made solution that can be white-labeled for partners looking to build a new app

## Features

- [x] **Sending payments** via various protocols such as: Bolt11, Bolt12, BIP353, LNURL-Pay, Lightning address, BTC address
- [x] **Receiving payments** via various protocols such as: Bolt11, LNURL-Withdraw, LNURL-Pay, Lightning address, BTC address
- [x] A built-in, customizable user@breez.fun Lightning address
- [x] Receive payments even when the app is offline (requires notifications)
- [x] No channel management 
- [x] Self-custodial: keys are only held by users
- [x] Free open-source software (ofc!)

## Installation 

[![Google Play](.github/assets/images/google-play.svg)](https://play.google.com/store/apps/details?id=com.breez.misty)   [![TestFlight](.github/assets/images/app-store.svg)](https://testflight.apple.com/join/nEegHvBX) 

## Coming Soon
- [ ] Improve usability w/o Google services 
- [ ] Receive to a BTC address w/o specifying an amount
- [ ] Receive using Bolt12
- [ ] Generate BIP353 address
- [ ] Auto-complete Lightning addresses from history 

## For Developers

Please refer to [Setting up your Environment](.github/docs/DEVENV_SETUP.md) for detailed instructions on configuring your local development environment.

### How do I contribute?

For guidance on contributing to the project, please refer to the [Contribution Guidelines](.github/docs/CONTRIBUTING.md).

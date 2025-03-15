# EV Bluetooth Shoe Controller

A Flutter application for controlling EV shoes via Bluetooth Low Energy (BLE). This app provides an intuitive interface to control both shoes independently, with features for speed control, battery monitoring, and safety features.

## Features

- BLE device scanning and connection
- Independent control for left and right shoes
- Real-time speed monitoring
- Battery level indication
- Emergency stop functionality
- User-friendly interface with joystick controls
- Settings for speed limits and control sensitivity

## Getting Started

1. Install Flutter SDK (>=3.2.3)
2. Clone this repository
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## BLE Protocol

The app communicates with the ESP32 using the following protocol:

- Service UUID: `fc96f65e-318a-4001-84bd-77e9d12af44b`
- TX Characteristic: `94b43599-5ea2-41e7-9d99-6ff9b904ae3a`
- RX Characteristic: `04d3552e-b9b3-4be6-a8b4-aa43c4507c4d`

Control Commands:
- Left Shoe: `[0x01, speed]` (speed: -128 to 127)
- Right Shoe: `[0x02, speed]` (speed: -128 to 127)

## Dependencies

- flutter_blue_plus: ^1.29.11
- flutter_joystick: ^0.0.4
- lottie: ^2.7.0
- go_router: ^12.1.1
- kdgaugeview: ^1.0.4
- shared_preferences: ^2.2.2

## Building for Release

1. Update version in pubspec.yaml
2. Build for Android:
   ```bash
   flutter build apk --release
   ```
3. Build for iOS:
   ```bash
   flutter build ios --release
   ```

## Contributing

Feel free to submit issues and enhancement requests! 
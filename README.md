# ESP32 EV Shoes Controller with Flutter App

This project implements a Bluetooth Low Energy (BLE) controlled EV shoes system using an ESP32 microcontroller and a Flutter mobile application. The system allows you to control two motors (one for each shoe) independently through a mobile app.

## Project Structure

```
.
├── Arduino_ESP32-S3_BLE_Server/    # ESP32 firmware
│   └── Arduino_ESP32-S3_BLE_Server.ino
└── Flutter_App/                    # Mobile application
    └── rc_controller_ble/         # Flutter project directory
```

## Hardware Requirements

- ESP32-S3 Development Board
- 2x DC Motors (one for each shoe)
- 2x Motor Drivers (L298N or similar)
- Power Supply (Battery)
- Connecting wires
- EV Shoes mechanical assembly

## Hardware Connections

### Motor Connections
1. Left Shoe Motor:
   - Forward Pin: GPIO 18 (LEFT_MOTOR_PIN_A)
   - Backward Pin: GPIO 19 (LEFT_MOTOR_PIN_B)

2. Right Shoe Motor:
   - Forward Pin: GPIO 21 (RIGHT_MOTOR_PIN_A)
   - Backward Pin: GPIO 22 (RIGHT_MOTOR_PIN_B)

### Power Connections
- Connect motor driver VCC to ESP32 5V or external power supply
- Connect motor driver GND to ESP32 GND
- Connect motors to motor driver output terminals
- Connect motor driver power to battery (ensure voltage matches motor requirements)

## ESP32 Setup

1. Install Required Libraries:
   - NimBLE-Arduino (by h2zero)
   - ESP32 Board Support Package

2. Arduino IDE Settings:
   - Board: "ESP32-S3 Dev Module"
   - Upload Speed: 921600
   - CPU Frequency: 240MHz
   - Flash Mode: QIO
   - Flash Size: 4MB
   - Partition Scheme: Default

3. Upload the Code:
   - Open `Arduino_ESP32-S3_BLE_Server.ino`
   - Select the correct COM port
   - Click Upload

## Flutter App Setup

1. Requirements:
   - Flutter SDK (>=3.2.3)
   - Android Studio or VS Code
   - Android/iOS device with BLE support

2. Dependencies:
   The app uses the following main packages:
   - flutter_blue_plus: ^1.29.11 (for BLE communication)
   - flutter_joystick: ^0.0.4 (for control interface)
   - lottie: ^2.7.0 (for animations)
   - go_router: ^12.1.1 (for navigation)
   - kdgaugeview: ^1.0.4 (for speed indicators)
   - shared_preferences: ^2.2.2 (for storing settings)

3. Install Dependencies:
   ```bash
   cd Flutter_App/rc_controller_ble
   flutter pub get
   ```

4. Run the App:
   ```bash
   flutter run
   ```

## App Features

1. Device Connection:
   - Scan and discover nearby BLE devices
   - Connect to ESP32 EV shoes controller
   - Auto-reconnect capability
   - Connection status indicator

2. Control Interface:
   - Dual joystick controls for both shoes
   - Speed indicators for each shoe
   - Emergency stop button
   - Battery level indicator (if implemented)
   - Settings page for customization

3. Settings Options:
   - Maximum speed limit
   - Control sensitivity
   - Connection preferences
   - Theme selection

## Using the System

1. Power up the ESP32 and EV shoes assembly
2. Launch the Flutter app on your mobile device
3. Enable Bluetooth on your mobile device
4. In the app:
   - Tap "Scan" to find available devices
   - Connect to "ESP32-EV-SHOES"
   - Use the controls to operate each shoe:
     - Left shoe control: Forward/Backward
     - Right shoe control: Forward/Backward

## BLE Protocol

The system uses a simple BLE protocol for communication:

1. Service UUID: `fc96f65e-318a-4001-84bd-77e9d12af44b`
2. Characteristic UUIDs:
   - TX: `94b43599-5ea2-41e7-9d99-6ff9b904ae3a`
   - RX: `04d3552e-b9b3-4be6-a8b4-aa43c4507c4d`

3. Control Commands:
   ```
   Left Shoe:  [0x01, speed]  // speed: -128 to 127
   Right Shoe: [0x02, speed]  // speed: -128 to 127
   ```
   - Positive speed: Forward motion
   - Negative speed: Backward motion
   - Zero speed: Stop

## Safety Features

- Motors automatically stop when BLE connection is lost
- Speed limits implemented in both firmware and app
- Emergency stop button in the app
- Battery level monitoring (if implemented in hardware)

## Troubleshooting

1. Connection Issues:
   - Ensure Bluetooth is enabled on your mobile device
   - Check if ESP32 is powered and running
   - Verify the ESP32 is advertising (Serial monitor shows "BLE Advertising Started...")
   - Try resetting the ESP32

2. Motor Issues:
   - Check motor driver connections
   - Verify power supply voltage
   - Check motor driver enable pins
   - Verify PWM signals using oscilloscope if available

3. App Issues:
   - Ensure app has Bluetooth permissions
   - Check if device supports BLE
   - Try clearing app cache
   - Reinstall the app if necessary

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- NimBLE-Arduino library developers
- Flutter BLE library contributors
- ESP32 community

## Contact

For questions or support, please open an issue in the repository. 
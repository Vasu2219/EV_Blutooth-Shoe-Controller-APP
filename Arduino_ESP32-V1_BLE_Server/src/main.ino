#include <NimBLEDevice.h>
#include <NimBLEServer.h>
#include <ESP32Servo.h>

#define BLE_NAME "ESP32-RC-CAR"
#define SERVICE_UUID "fc96f65e-318a-4001-84bd-77e9d12af44b"
#define CHARACTERISTIC_UUID_TX "94b43599-5ea2-41e7-9d99-6ff9b904ae3a"
#define CHARACTERISTIC_UUID_RX "04d3552e-b9b3-4be6-a8b4-aa43c4507c4d"

// ESP32-S3 specific pin assignments
#define SERVO_PIN 17    // Updated for ESP32-S3
#define MOTOR_PIN_A 18  // Updated for ESP32-S3
#define MOTOR_PIN_B 19  // Updated for ESP32-S3

Servo servo_motor;
int servoAngle = 90;
int motorSpeed = 0;

NimBLEServer* pServer = nullptr;
NimBLECharacteristic* pCharacteristicTX = nullptr;
NimBLECharacteristic* pCharacteristicRX = nullptr;
bool deviceConnected = false;

class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
        deviceConnected = true;
        Serial.println("Client Connected!");
        Serial.printf("Client Address: %s\n", pServer->getPeerInfo(0).getAddress().toString().c_str());
    };

    void onDisconnect(NimBLEServer* pServer) {
        deviceConnected = false;
        Serial.println("Client Disconnected");
        // Stop motors on disconnect for safety
        analogWrite(MOTOR_PIN_A, 0);
        analogWrite(MOTOR_PIN_B, 0);
        servo_motor.write(90);  // Center position
        
        // Restart advertising
        Serial.println("Restarting advertising...");
        startAdvertising();
    }
};

class CharacteristicCallbacks: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pCharacteristic) {
        std::string value = pCharacteristic->getValue();
        if (value.length() > 0) {
            Serial.print("Received Value: ");
            for (int i = 0; i < value.length(); i++) {
                Serial.printf("%02X ", value[i]);
            }
            Serial.println();

            // Process the command
            uint8_t* data = (uint8_t*)value.data();
            if (value.length() >= 2) {  // Changed to >= to be more defensive
                switch (data[0]) {
                    case 0x01:  // DC Motor
                        motorSpeed = (int8_t)data[1];  // Convert to signed value
                        Serial.printf("Motor Speed: %d\n", motorSpeed);
                        if (motorSpeed > 0) {
                            analogWrite(MOTOR_PIN_A, min(abs(motorSpeed) * 2, 255));
                            analogWrite(MOTOR_PIN_B, 0);
                        } else if (motorSpeed < 0) {
                            analogWrite(MOTOR_PIN_A, 0);
                            analogWrite(MOTOR_PIN_B, min(abs(motorSpeed) * 2, 255));
                        } else {
                            analogWrite(MOTOR_PIN_A, 0);
                            analogWrite(MOTOR_PIN_B, 0);
                        }
                        break;

                    case 0x02:  // Servo
                        servoAngle = constrain(data[1], 0, 180);
                        Serial.printf("Servo Angle: %d\n", servoAngle);
                        servo_motor.write(servoAngle);
                        break;
                }
            }
        }
    }
};

void startAdvertising() {
    // Start advertising
    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    
    // Clear any existing advertising config
    pAdvertising->reset();
    
    // Add the service UUID
    pAdvertising->addServiceUUID(SERVICE_UUID);
    
    // Set advertising parameters
    pAdvertising->setName(BLE_NAME);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
    pAdvertising->setMaxPreferred(0x12);
    
    // Start advertising
    NimBLEDevice::startAdvertising();
    
    Serial.println("Advertising started with parameters:");
    Serial.printf("Device Name: %s\n", BLE_NAME);
    Serial.printf("Service UUID: %s\n", SERVICE_UUID);
    Serial.printf("MAC Address: %s\n", NimBLEDevice::getAddress().toString().c_str());
}

void setup() {
    Serial.begin(115200);
    Serial.println("\nStarting BLE Server...");

    // Initialize motors with PWM frequency for smoother operation
    pinMode(MOTOR_PIN_A, OUTPUT);
    pinMode(MOTOR_PIN_B, OUTPUT);
    
    // Configure PWM for motor control
    ledcSetup(0, 5000, 8);  // Channel 0, 5000 Hz, 8-bit resolution
    ledcSetup(1, 5000, 8);  // Channel 1, 5000 Hz, 8-bit resolution
    ledcAttachPin(MOTOR_PIN_A, 0);
    ledcAttachPin(MOTOR_PIN_B, 1);
    
    // Initialize servo
    ESP32PWM::allocateTimer(0);
    servo_motor.setPeriodHertz(50);    // Standard 50 Hz servo
    servo_motor.attach(SERVO_PIN, 500, 2400);  // attaches the servo with custom pulse width
    servo_motor.write(90);  // Center position
    Serial.println("Motors initialized");

    // Initialize BLE
    NimBLEDevice::init(BLE_NAME);
    NimBLEDevice::setPower(ESP_PWR_LVL_P9); // Increase transmit power to maximum
    Serial.println("BLE initialized with maximum power");
    
    // Create the BLE Server
    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    Serial.println("Server created");

    // Create the BLE Service
    NimBLEService* pService = pServer->createService(SERVICE_UUID);
    Serial.println("Service created");

    // Create BLE Characteristics
    pCharacteristicTX = pService->createCharacteristic(
        CHARACTERISTIC_UUID_TX,
        NIMBLE_PROPERTY::NOTIFY
    );
    
    pCharacteristicRX = pService->createCharacteristic(
        CHARACTERISTIC_UUID_RX,
        NIMBLE_PROPERTY::WRITE
    );
    pCharacteristicRX->setCallbacks(new CharacteristicCallbacks());
    Serial.println("Characteristics created");

    // Start the service
    pService->start();
    Serial.println("Service started");

    // Start advertising
    startAdvertising();
}

void loop() {
    // Print status every 5 seconds
    static unsigned long lastPrint = 0;
    if (millis() - lastPrint >= 5000) {
        lastPrint = millis();
        Serial.printf("Status: %s\n", deviceConnected ? "Connected" : "Waiting for connection");
        Serial.printf("Advertising: %s\n", NimBLEDevice::getAdvertising()->isAdvertising() ? "Yes" : "No");
        
        // If not advertising and not connected, restart advertising
        if (!NimBLEDevice::getAdvertising()->isAdvertising() && !deviceConnected) {
            Serial.println("Restarting advertising...");
            startAdvertising();
        }
    }
    delay(100);
} 
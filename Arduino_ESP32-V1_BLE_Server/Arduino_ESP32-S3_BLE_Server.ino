#include <NimBLEDevice.h>

// BLE Configuration
#define BLE_NAME "ESP32-EV-SHOES"
#define SERVICE_UUID "fc96f65e-318a-4001-84bd-77e9d12af44b"
#define CHARACTERISTIC_UUID_TX "94b43599-5ea2-41e7-9d99-6ff9b904ae3a"
#define CHARACTERISTIC_UUID_RX "04d3552e-b9b3-4be6-a8b4-aa43c4507c4d"

// Motor pin definitions
#define LEFT_MOTOR_PIN_A 18    // Left shoe motor forward
#define LEFT_MOTOR_PIN_B 19    // Left shoe motor backward
#define RIGHT_MOTOR_PIN_A 21   // Right shoe motor forward
#define RIGHT_MOTOR_PIN_B 22   // Right shoe motor backward

// PWM Channels
#define LEFT_MOTOR_CH_A 0
#define LEFT_MOTOR_CH_B 1
#define RIGHT_MOTOR_CH_A 2
#define RIGHT_MOTOR_CH_B 3

// Global variables
NimBLEServer* pServer = nullptr;
NimBLECharacteristic* pCharacteristicTX = nullptr;
NimBLECharacteristic* pCharacteristicRX = nullptr;
bool deviceConnected = false;
int8_t leftMotorSpeed = 0;
int8_t rightMotorSpeed = 0;

// Motor control functions
void initMotors() {
    pinMode(LEFT_MOTOR_PIN_A, OUTPUT);
    pinMode(LEFT_MOTOR_PIN_B, OUTPUT);
    pinMode(RIGHT_MOTOR_PIN_A, OUTPUT);
    pinMode(RIGHT_MOTOR_PIN_B, OUTPUT);

    ledcSetup(LEFT_MOTOR_CH_A, 5000, 8);   // 5kHz PWM, 8-bit resolution
    ledcSetup(LEFT_MOTOR_CH_B, 5000, 8);
    ledcSetup(RIGHT_MOTOR_CH_A, 5000, 8);
    ledcSetup(RIGHT_MOTOR_CH_B, 5000, 8);

    ledcAttachPin(LEFT_MOTOR_PIN_A, LEFT_MOTOR_CH_A);
    ledcAttachPin(LEFT_MOTOR_PIN_B, LEFT_MOTOR_CH_B);
    ledcAttachPin(RIGHT_MOTOR_PIN_A, RIGHT_MOTOR_CH_A);
    ledcAttachPin(RIGHT_MOTOR_PIN_B, RIGHT_MOTOR_CH_B);

    stopMotors();
}

void setMotorSpeed(bool isLeft, int8_t speed) {
    uint8_t channelA = isLeft ? LEFT_MOTOR_CH_A : RIGHT_MOTOR_CH_A;
    uint8_t channelB = isLeft ? LEFT_MOTOR_CH_B : RIGHT_MOTOR_CH_B;
    
    if (speed > 0) {
        ledcWrite(channelA, min(abs(speed) * 2, 255));
        ledcWrite(channelB, 0);
    } else if (speed < 0) {
        ledcWrite(channelA, 0);
        ledcWrite(channelB, min(abs(speed) * 2, 255));
    } else {
        ledcWrite(channelA, 0);
        ledcWrite(channelB, 0);
    }

    if (isLeft) {
        leftMotorSpeed = speed;
    } else {
        rightMotorSpeed = speed;
    }
}

void stopMotors() {
    setMotorSpeed(true, 0);   // Stop left motor
    setMotorSpeed(false, 0);  // Stop right motor
}

// BLE Callbacks
class ServerCallbacks: public NimBLEServerCallbacks {
    void onDisconnect(NimBLEServer* pServer) {
        deviceConnected = false;
        Serial.println("Client Disconnected");
        stopMotors();
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

            uint8_t* data = (uint8_t*)value.data();
            if (value.length() >= 2) {
                switch (data[0]) {
                    case 0x01:  // Left Shoe Motor
                        setMotorSpeed(true, (int8_t)data[1]);
                        Serial.printf("Left Motor Speed: %d\n", (int8_t)data[1]);
                        break;

                    case 0x02:  // Right Shoe Motor
                        setMotorSpeed(false, (int8_t)data[1]);
                        Serial.printf("Right Motor Speed: %d\n", (int8_t)data[1]);
                        break;
                }
            }
        }
    }
};

void startAdvertising() {
    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->reset();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setName(BLE_NAME);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMaxPreferred(0x12);
    NimBLEDevice::startAdvertising();
    Serial.println("BLE Advertising Started...");
}

void setup() {
    Serial.begin(115200);
    Serial.println("\nStarting ESP32 EV Shoes Controller...");

    // Initialize motors
    initMotors();
    Serial.println("Motors Initialized");

    // Initialize BLE
    NimBLEDevice::init(BLE_NAME);
    NimBLEDevice::setPower(ESP_PWR_LVL_P9);
    
    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    NimBLEService* pService = pServer->createService(SERVICE_UUID);
    
    pCharacteristicTX = pService->createCharacteristic(
        CHARACTERISTIC_UUID_TX,
        NIMBLE_PROPERTY::NOTIFY
    );
    
    pCharacteristicRX = pService->createCharacteristic(
        CHARACTERISTIC_UUID_RX,
        NIMBLE_PROPERTY::WRITE
    );
    pCharacteristicRX->setCallbacks(new CharacteristicCallbacks());

    pService->start();
    startAdvertising();
}

void loop() {
    static unsigned long lastPrint = 0;
    if (millis() - lastPrint >= 5000) {
        lastPrint = millis();
        Serial.printf("Status: %s\n", deviceConnected ? "Connected" : "Waiting for connection");
        if (deviceConnected) {
            Serial.printf("Left Motor: %d, Right Motor: %d\n", leftMotorSpeed, rightMotorSpeed);
        }
    }
    delay(100);
}

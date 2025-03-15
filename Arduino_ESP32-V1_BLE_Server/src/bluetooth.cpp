#include <Arduino.h>  // Added this to fix 'Serial' and 'delay' errors
#include "bluetooth.h"
#include <BLEUtils.h>
#include <BLE2902.h>

// Global BLE Objects
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristicTX = nullptr;
BLECharacteristic* pCharacteristicRX = nullptr;

// BLE Server Callback (Handles Client Connections)
class ServerCallback : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    Serial.println("Client Connected!");
  }

  void onDisconnect(BLEServer* pServer) {
    Serial.println("Client Disconnected. Restarting Advertising...");
    delay(1000); // Short delay before restarting advertising
    BLEDevice::startAdvertising();
  }
};

// BLE RX Callback (Handles Incoming Data)
class RXCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (!value.empty()) {
      Serial.print("Received Data: ");
      Serial.println(value.c_str());
    }
  }
};

// BLE Setup Function
void setupBLE() {
  BLEDevice::init(BLE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallback());

  // Create BLE Service
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // TX Characteristic (Notify)
  pCharacteristicTX = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TX,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristicTX->addDescriptor(new BLE2902());

  // RX Characteristic (Write)
  pCharacteristicRX = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE
  );
  pCharacteristicRX->setCallbacks(new RXCallback());
  pCharacteristicRX->addDescriptor(new BLE2902());

  // Start BLE Service
  pService->start();

  // Start Advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);

  BLEDevice::startAdvertising();
  Serial.println("BLE Server Started. Waiting for a connection...");
}

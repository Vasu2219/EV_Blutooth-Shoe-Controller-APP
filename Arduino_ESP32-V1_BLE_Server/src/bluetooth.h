#ifndef BLUETOOTH_H
#define BLUETOOTH_H

#include <BLEDevice.h>
#include <BLEServer.h>

// BLE UUIDs (Make sure they match your BLE client app)
#define BLE_NAME "ESP32-RC-CAR"
#define SERVICE_UUID "fc96f65e-318a-4001-84bd-77e9d12af44b"
#define CHARACTERISTIC_UUID_TX "94b43599-5ea2-41e7-9d99-6ff9b904ae3a"
#define CHARACTERISTIC_UUID_RX "04d3552e-b9b3-4be6-a8b4-aa43c4507c4d"

// Global BLE Server
extern BLEServer* pServer;

// BLE Setup Function
void setupBLE();

#endif

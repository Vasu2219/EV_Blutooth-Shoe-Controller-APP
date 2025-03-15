import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../utils/extra.dart';
import 'constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  List<BluetoothDevice> _connectedDevices = [];
  List<ScanResult> _scanResults = [];
  Map<String, int> _deviceStabilityCount = {};  // Track device appearance count
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  BluetoothDevice? targetDevice;
  String? targetMacAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTargetMacAddress();
    bleInit();
  }

  Future<void> _loadTargetMacAddress() async {
    final mac = await getTargetMacAddress();
    setState(() {
      targetMacAddress = mac;
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isScanning && targetDevice == null) {
          onScanning();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        onStopScanning();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void bleInit() {
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      print('Bluetooth adapter state changed: $state');
      _adapterState = state;
      if (state == BluetoothAdapterState.on) {
        print('Bluetooth is ON - starting scan');
        onScanning();
      }
      setState(() {});
    });

    _connectedDevices = FlutterBluePlus.connectedDevices;
    print('Currently connected devices: ${_connectedDevices.map((d) => '${d.remoteId.str} - ${d.platformName}')}');
    setState(() {});

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      print('Scan results: ${results.length} devices found');
      
      // Update stability count for each device
      for (var r in results) {
        String deviceId = r.device.remoteId.str;
        _deviceStabilityCount[deviceId] = (_deviceStabilityCount[deviceId] ?? 0) + 1;
        print('Device found: ${r.device.remoteId.str} - ${r.device.platformName} - RSSI: ${r.rssi} - Stability: ${_deviceStabilityCount[deviceId]}');
      }

      // Filter results to show only stable devices (seen at least 2 times)
      List<ScanResult> stableResults = results.where((r) => 
        (_deviceStabilityCount[r.device.remoteId.str] ?? 0) >= 2
      ).toList();

      setState(() {
        _scanResults = stableResults;
      });

      findTargetDevice();
    }, onError: (e) {
      print('Error during scan: $e');
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      print('Scanning state changed: $state');
      _isScanning = state;
      setState(() {});
    });

    // Start initial scan if Bluetooth is on
    if (_adapterState == BluetoothAdapterState.on) {
      print('Bluetooth is already ON - starting initial scan');
      onScanning();
    }
  }

  Future<void> onScanning() async {
    try {
      print('Starting BLE scan...');
      await FlutterBluePlus.stopScan();
      
      // Clear previous results and stability counts when starting new scan
      setState(() {
        _scanResults.clear();
        _deviceStabilityCount.clear();
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('Setting scan settings...');
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        androidUsesFineLocation: true,
      );
      
      // Automatically restart scan after timeout
      Future.delayed(const Duration(seconds: 9), () {
        if (mounted && targetDevice == null) {
          onScanning();
        }
      });
      
      print('Scan started successfully');
      return Future<void>.value();
    } catch (e) {
      print('Error starting scan: $e');
      return Future<void>.value();
    }
  }

  Future onStopScanning() async {
    try {
      print('Stopping BLE scan...');
      await FlutterBluePlus.stopScan();
      print('Scan stopped successfully');
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  void findTargetDevice() async {
    if (targetMacAddress == null) {
      print('Target MAC address not set');
      return;
    }

    print('Looking for device with MAC: $targetMacAddress');
    final index = _scanResults
        .indexWhere((item) => item.device.remoteId.str.toUpperCase() == targetMacAddress!.toUpperCase());
    
    if (index >= 0) {
      print('Target device found!');
      targetDevice = _scanResults[index].device;
      print('Device name: ${targetDevice?.platformName}');
      print('Device ID: ${targetDevice?.remoteId.str}');
      print('RSSI: ${_scanResults[index].rssi}');

      await onStopScanning();

      print('Attempting to connect...');
      try {
        await targetDevice?.connectAndUpdateStream().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Connection timeout');
          },
        );
        
        print('Connection successful!');
        
        if (targetDevice?.isConnected == true) {
          print('Device is confirmed connected');
          await Future.delayed(const Duration(seconds: 1));

          if (!context.mounted) return;
          var result = await context.pushNamed(
            'controller',
            extra: targetDevice,
          );

          if (result != null && result == true) {
            onScanning();
          }
        } else {
          print('Device connection state is false after connect');
          onScanning();
        }
      } catch (e) {
        print('Error during connection: $e');
        await targetDevice?.disconnectAndUpdateStream().catchError((e) {
          print('Error during disconnect: $e');
        });
        onScanning();
      }
    }
  }

  // Filter and sort scan results
  List<ScanResult> get _filteredAndSortedResults {
    return _scanResults
        .toList()  // Show all devices, don't filter by name
        ..sort((a, b) => b.rssi.compareTo(a.rssi)); // Sort by signal strength
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RC Controller'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await context.pushNamed('settings');
              _loadTargetMacAddress();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => onScanning(),
        child: Column(
          children: [
            // Bluetooth Off Warning
            if (_adapterState != BluetoothAdapterState.on)
              Container(
                color: Colors.red,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bluetooth is required for device connection',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    if (Platform.isAndroid)
                      TextButton(
                        onPressed: () {
                          FlutterBluePlus.turnOn().then((_) {
                            print('Bluetooth turned on successfully');
                          }).catchError((e) {
                            print('Error turning on Bluetooth: $e');
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'TURN ON',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

            // Scan Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Devices',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_adapterState == BluetoothAdapterState.on)
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : onScanning,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                    ),
                ],
              ),
            ),

            // Device List
            Expanded(
              child: _filteredAndSortedResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            size: 48,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isScanning 
                                ? 'Searching for nearby devices...'
                                : 'No devices found\nTap Scan to start searching',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredAndSortedResults.length,
                      itemBuilder: (context, index) {
                        final result = _filteredAndSortedResults[index];
                        final device = result.device;
                        final name = device.platformName.isNotEmpty
                            ? device.platformName
                            : 'Unknown Device';
                        final isMacMatch = targetMacAddress != null && 
                            device.remoteId.str.toUpperCase() == targetMacAddress!.toUpperCase();
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: isMacMatch 
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bluetooth,
                                color: isMacMatch ? Colors.white : Colors.blue,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: isMacMatch ? FontWeight.bold : null,
                                        ),
                                      ),
                                      Text(
                                        device.remoteId.str,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMacMatch)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Target Device',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.signal_cellular_alt,
                                  size: 14,
                                  color: _getRssiColor(result.rssi),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${result.rssi} dBm',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _connectToDevice(device),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isMacMatch ? Colors.green : Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Connect'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await onStopScanning();
    
    print('Attempting to connect to ${device.platformName}...');
    try {
      await device.connectAndUpdateStream().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );
      
      print('Connection successful!');
      
      if (device.isConnected == true) {
        print('Device is confirmed connected');
        await Future.delayed(const Duration(seconds: 1));

        if (!context.mounted) return;
        var result = await context.pushNamed(
          'controller',
          extra: device,
        );

        if (result != null && result == true) {
          onScanning();
        }
      } else {
        print('Device connection state is false after connect');
        onScanning();
      }
    } catch (e) {
      print('Error during connection: $e');
      await device.disconnectAndUpdateStream().catchError((e) {
        print('Error during disconnect: $e');
      });
      onScanning();
    }
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }
}

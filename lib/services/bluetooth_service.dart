import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutterBlue;
import 'dart:async';

class BluetoothService {
  bool _isScanning = false; // Prevent scanning too frequently

  // Request Bluetooth & Location Permissions
  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();
  }

  // Start scanning for Bluetooth devices
  Stream<List<flutterBlue.ScanResult>> scanForDevices() async* {
    await requestPermissions(); // 🔹 Make sure to call this before scanning!

    if (_isScanning) {
      print("⚠️ Scan already running. Skipping new scan request.");
      return;
    }

    _isScanning = true;
    print("🔍 Starting Bluetooth Scan...");

    // Stop any existing scan before starting a new one
    await flutterBlue.FlutterBluePlus.stopScan();
    await Future.delayed(const Duration(seconds: 1));

    // Start scanning
    flutterBlue.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Continuously listen for scan results and yield them
    await for (var results in flutterBlue.FlutterBluePlus.scanResults) {
      if (results.isNotEmpty) {
        for (var result in results) {
          print(
              "📡 Device Found: ${result.device.remoteId} - ${result.device.name}");
        }
        yield results; // Send results to the stream
      }
    }

    // Stop scanning after 10 seconds
    await Future.delayed(const Duration(seconds: 10));
    await flutterBlue.FlutterBluePlus.stopScan();

    _isScanning = false;
    print("🔴 Scan Stopped");
  }

  // Connect to a Bluetooth device
  Future<void> connectToDevice(flutterBlue.BluetoothDevice device) async {
    try {
      await device.connect();
    } catch (e) {
      if (e.toString().contains('already connected')) {
        print("✅ Device already connected.");
      } else {
        print("❌ Error connecting: $e");
      }
    }
  }

  // Disconnect from a Bluetooth device
  Future<void> disconnectDevice(flutterBlue.BluetoothDevice device) async {
    await device.disconnect();
  }
}

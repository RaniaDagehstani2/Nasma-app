import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as flutterBlue;
import 'package:testtest/screens/homepage.dart';
import 'sign_up_next_screen.dart';
import 'package:testtest/services/bluetooth_service.dart';
import 'package:testtest/screens/medical_data_screen.dart';

class ConnectPatchScreen extends StatefulWidget {
  final String userId; // ✅ Add this to receive userId
  final bool showBackButton; // 🔹 New parameter to control the `<` button

  const ConnectPatchScreen(
      {Key? key, required this.userId, this.showBackButton = true})
      : super(key: key);
  @override
  _ConnectPatchScreenState createState() => _ConnectPatchScreenState();
}

class _ConnectPatchScreenState extends State<ConnectPatchScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<flutterBlue.ScanResult> scanResults = [];
  List<flutterBlue.BluetoothDevice> connectedDevices = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  // Start Bluetooth scanning
  void _startScan() {
    _bluetoothService.scanForDevices().listen((results) {
      setState(() {
        scanResults = results;
      });

      if (scanResults.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No Bluetooth devices found. Try again!")),
        );
      }
    });
  }

  // Connect to a Bluetooth device
  void _connectDevice(flutterBlue.BluetoothDevice device) async {
    await _bluetoothService.connectToDevice(device);
    setState(() {
      connectedDevices.add(device);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${device.localName} connected successfully!")),
    );
  }

  // Disconnect from a Bluetooth device
  void _disconnectDevice(flutterBlue.BluetoothDevice device) async {
    await _bluetoothService.disconnectDevice(device);
    setState(() {
      connectedDevices.remove(device);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${device.localName} disconnected!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildDeviceList(),
            const SizedBox(height: 20),
            _buildStartButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget _buildHeader() {
  //   return Container(
  //     width: double.infinity,
  //     height: 240,
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF6676AA),
  //       borderRadius: const BorderRadius.only(
  //         bottomLeft: Radius.circular(40),
  //         bottomRight: Radius.circular(40),
  //       ),
  //     ),
  //     child: Stack(
  //       alignment: Alignment.center,
  //       children: [
  //         if (widget.showBackButton) // 🔹 Show only when needed
  //           Positioned(
  //             top: 20,
  //             left: 20,
  //             child: IconButton(
  //               icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
  //               onPressed: () {
  //                 Navigator.pushReplacement(
  //                   context,
  //                   MaterialPageRoute(
  //                       builder: (context) =>
  //                           HomeScreen(userId: widget.userId)),
  //                 );
  //               },
  //             ),
  //           ),
  //         Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Stack(
  //               alignment: Alignment.center,
  //               children: [
  //                 for (int i = 0; i < 5; i++)
  //                   Container(
  //                     width: 120 - (i * 10),
  //                     height: 120 - (i * 10),
  //                     decoration: BoxDecoration(
  //                       shape: BoxShape.circle,
  //                       border: Border.all(
  //                           color: Colors.white.withOpacity(0.5), width: 0.8),
  //                     ),
  //                   ),
  //                 Image.asset(
  //                   "assets/blutooth.png",
  //                   width: 80,
  //                   height: 80,
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 15),
  //             Text(
  //               "CONNECT PATCH",
  //               style: GoogleFonts.poppins(
  //                 fontSize: 22,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white,
  //                 letterSpacing: 1,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF8699DA),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () {
                if (widget.showBackButton) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(userId: widget.userId),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MedicalDataScreen(userId: widget.userId),
                    ),
                  );
                }
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < 5; i++)
                    Container(
                      width: 120 - (i * 10),
                      height: 120 - (i * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 0.8),
                      ),
                    ),
                  Image.asset(
                    "assets/blutooth.png",
                    width: 80,
                    height: 80,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "CONNECT PATCH",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // UI for Bluetooth Device List
  Widget _buildDeviceList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: scanResults.isEmpty
            ? _buildNoDevicesFound()
            : ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  return _buildPatchTile(index);
                },
              ),
      ),
    );
  }

  // UI for No Devices Found Message
  Widget _buildNoDevicesFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            "No Bluetooth devices found.\nMake sure Bluetooth is ON and try again.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8699DA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              "RETRY SCAN",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // UI for Device Tiles
  Widget _buildPatchTile(int index) {
    final device = scanResults[index].device;
    bool isConnected = connectedDevices.contains(device);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                "assets/nasmapatch.png",
                width: 30,
                height: 30,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name.isNotEmpty ? device.name : "Unknown Device",
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  Text(
                    device.remoteId.toString(),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              isConnected ? _disconnectDevice(device) : _connectDevice(device);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8699DA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isConnected ? "UNPAIR" : "PAIR",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () {
          if (connectedDevices.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Please connect a patch first!")),
            );
          } else {
            if (!widget.showBackButton) {
              // 🟢 If `showBackButton == false`, go to Sign Up Next Screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MedicalDataScreen(userId: widget.userId),
                ),
              );
            } else {
              // 🟢 If `showBackButton == true`, go back to Home Page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(userId: widget.userId),
                ),
              );
            }
          }
        },
        /* */
        // style: ElevatedButton.styleFrom(
        //   backgroundColor: const Color(0xFF8699DA),
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(30),
        //   ),
        //   padding: const EdgeInsets.symmetric(vertical: 14),
        // ),
        // child: Text(
        //   "LET'S START!",
        //   style: GoogleFonts.poppins(
        //     fontSize: 16,
        //     color: Colors.white,
        //     fontWeight: FontWeight.bold,
        //   ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8699DA), // Same button color
          padding: const EdgeInsets.symmetric(vertical: 14), // Same padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Same rounded corners
          ),
        ),
        child: Text(
          "Done!",
          style: TextStyle(
            fontSize: 19, // Same font size
            fontFamily: "Nunito", // Same font family
            fontWeight: FontWeight.bold, // Same bold text
            color: Colors.white, // Same text color
          ),
        ),
      ),
    );
  }
}

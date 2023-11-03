import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:trebesin_rc_auto/select_bonded_device_page.dart';

BluetoothConnection? connection;
void send(String text) async {
  connection?.output.add(Uint8List.fromList(utf8.encode("$text\r\n")));
  await connection?.output.allSent;
}

void bluetooth(BuildContext context) async {
  if (connection != null) {
    connection?.dispose();
    connection = null;
  }
  await Permission.bluetooth.request();
  await Permission.bluetoothAdvertise.request();
  await Permission.bluetoothConnect.request();
  await Permission.bluetoothScan.request();
  await Permission.location.request();
  if (!context.mounted) return;
  final BluetoothDevice? selectedDevice = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return const SelectBondedDevicePage(checkAvailability: false);
      },
    ),
  );
  BluetoothDevice? server = selectedDevice;
  if (server == null) {
    if (kDebugMode) {
      print('Connect -> no device selected');
    }
    return;
  }

  if (selectedDevice != null) {
    if (kDebugMode) {
      print('Connect -> selected ${selectedDevice.address}');
    }
    BluetoothConnection.toAddress(server.address).then((localConnection) {
      if (kDebugMode) {
        print('Connected to the device');
      }
      connection = localConnection;

      connection!.input!.listen(null).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (kDebugMode) {
          print('Disconnected!');
        }
      });
    }).catchError((error) {
      if (kDebugMode) {
        print('Cannot connect, exception occured');
      }
      if (kDebugMode) {
        print(error);
      }
    });
  } else {
    if (kDebugMode) {
      print('Connect -> no device selected');
    }
  }
}

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trebesin RC Auto Ovladac',
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double x = 0, y = 0, z = 0;
  @override
  void initState() {
    gyroscopeEvents.listen((GyroscopeEvent event) {
      x += event.x;
      y += event.y;
      z += event.z;

      //rough calculation, you can use
      //advance formula to calculate the orentation
      if (z > 0) {
        direction = "left";
      } else if (z < 0) {
        direction = "right";
      }

      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (connection != null) {
      connection?.dispose();
      connection = null;
    }
    super.dispose();
  }

  String direction = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () => bluetooth(context),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("RC Auto Ovladač"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                "Ovládání",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                "Připojeno: ${connection?.isConnected ?? false}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                "Gyroskop: $direction",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ElevatedButton(
                  onPressed: () {
                    x = 0;
                    y = 0;
                    z = 0;
                  },
                  child: const Text("Reset")),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //up
                  MaterialButton(
                    shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      send("W");
                    },
                    child: const Icon(
                      Icons.arrow_circle_up,
                      size: 90,
                    ),
                  ),

                  //down

                  MaterialButton(
                    shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      send("B");
                    },
                    child: const Icon(
                      Icons.arrow_circle_down,
                      size: 90,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

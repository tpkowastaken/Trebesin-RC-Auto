import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:trebesin_rc_auto/select_bonded_device_page.dart';
import 'package:material_symbols_icons/symbols.dart';

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
  // ignore: use_build_context_synchronously
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
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: 'Trebesin RC Auto Ovladac',
      debugShowCheckedModeBanner: false,
      //debugShowMaterialGrid: true,
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
      if (z > (0.4)) {
        direction = "Left";
      } else if (z < (-0.4)) {
        direction = "Right";
      } else {
        direction = "Straight";
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
  double _value = 0;
  bool steeringButtonsDissabled = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Symbols.bluetooth),
            onPressed: () => bluetooth(context),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("RC Auto Ovladač"),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 200),
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
                    child: const Text("Reset"),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IntrinsicHeight(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1.5,
                        style: BorderStyle.solid,
                        color: Colors.black38,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        //power button
                        IconButton(
                          icon: const Icon(
                            Symbols.power_settings_new,
                            size: 40,
                          ),
                          onPressed: () {},
                        ),
                        // vertical divider
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: VerticalDivider(
                            width: 1,
                            color: Colors.grey,
                          ),
                        ),
                        // switch steering mode button
                        IconButton(
                          icon: const Icon(
                            Symbols.swap_horiz,
                            size: 40,
                          ),
                          onPressed: () {
                            setState(() {
                              steeringButtonsDissabled = !steeringButtonsDissabled;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //stop button
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: MaterialButton(
                      shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
                        setState(() {
                          _value = 0;
                        });
                      },
                      child: const Icon(
                        Icons.stop_circle_outlined,
                        size: 50,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Symbols.stat_3,
                                size: 75,
                                color: Colors.orange,
                              ),
                              SizedBox(
                                width: 40,
                                child: Divider(
                                  color: Colors.black26,
                                  thickness: 1.5,
                                ),
                              ),
                              Icon(
                                Symbols.stat_minus_3,
                                size: 75,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          RotatedBox(
                            quarterTurns: 3,
                            child: SizedBox(
                              width: 225,
                              child: Slider.adaptive(
                                thumbColor: Theme.of(context).colorScheme.primary,
                                activeColor: Colors.transparent,
                                inactiveColor: Colors.transparent,
                                overlayColor: const MaterialStatePropertyAll(Colors.transparent),
                                min: -1,
                                max: 1,
                                value: _value,
                                onChanged: (value) {
                                  setState(() {
                                    _value = value;
                                  });
                                  if (kDebugMode) {
                                    print(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      //up
                      //MaterialButton(
                      //  shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                      //  padding: const EdgeInsets.all(0),
                      //  onPressed: () {
                      //  send("W");
                      //  },
                      //  child: const Icon(
                      //    Symbols.arrow_circle_up,
                      //    size: 90,
                      //  ),
                      //),

                      //down
                      //MaterialButton(
                      //  shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                      //  padding: const EdgeInsets.all(0),
                      //  onPressed: () {
                      //    send("B");
                      //  },
                      //  child: const Icon(
                      //    Symbols.arrow_circle_down,
                      //    size: 90,
                      //  ),
                      //),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: steeringButtonsDissabled
                    ? const Row(
                        children: [
                          Icon(
                            Symbols.arrow_circle_left_rounded,
                            size: 100,
                            color: Colors.black26,
                          ),
                          Icon(
                            Symbols.arrow_circle_right_rounded,
                            size: 100,
                            color: Colors.black26,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          //steer left
                          GestureDetector(
                            onTapDown: (details) {},
                            onTapUp: (details) {},
                            onTapCancel: () {},
                            child: const Icon(
                              Symbols.arrow_circle_left_rounded,
                              size: 100,
                              color: Colors.black,
                            ),
                          ),
                          //steer right

                          GestureDetector(
                            onTapDown: (details) {},
                            onTapUp: (details) {},
                            onTapCancel: () {},
                            child: const Icon(
                              Symbols.arrow_circle_right_rounded,
                              size: 100,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

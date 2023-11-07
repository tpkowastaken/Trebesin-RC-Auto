import 'dart:convert';
import 'dart:math';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:trebesin_rc_auto/select_bonded_device_page.dart';
import 'package:material_symbols_icons/symbols.dart';

const double defaultGyroSensitivity = 1.5;
const double defaultDeadZone = 0;

BluetoothConnection? connection;
Future<void> send(String text, {BluetoothConnection? customConnection}) async {
  if (customConnection != null) {
    customConnection.output.add(Uint8List.fromList(utf8.encode("$text\r\n")));
    await customConnection.output.allSent;
    return;
  }
  connection?.output.add(Uint8List.fromList(utf8.encode("$text\r\n")));
  await connection?.output.allSent;
}

Future<void> bluetooth(BuildContext context) async {
  BluetoothConnection? currentConnection = connection;
  connection = null;
  if (currentConnection != null) {
    await Future.delayed(const Duration(milliseconds: 150));
    await send("0.0|0.0", customConnection: currentConnection);
    await Future.delayed(const Duration(milliseconds: 50));
    currentConnection.dispose();
    return;
  }
  await Permission.bluetooth.request();
  await Permission.bluetoothAdvertise.request();
  await Permission.bluetoothConnect.request();
  await Permission.bluetoothScan.request();
  await Permission.location.request();
  if (await Permission.location.isDenied || await Permission.location.isRestricted || await Permission.location.isPermanentlyDenied) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nemáte povolenou polohu. Nevíme proč, ale pro připojení k arduinu je potřeba povolení polohy...")));
    }
    return;
  }
  if (await Permission.bluetooth.isDenied || await Permission.bluetooth.isRestricted || await Permission.bluetooth.isPermanentlyDenied) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Nemáte povolený bluetooth (přístup k blízkým zařízením). Pro připojení k arduinu je potřeba povolení bluetooth...")));
    }
    return;
  }
  if (await Permission.bluetoothScan.isDenied || await Permission.bluetoothScan.isRestricted || await Permission.bluetoothScan.isPermanentlyDenied) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Nemáte povolený bluetooth (přístup k blízkým zařízením). Pro připojení k arduinu je potřeba povolení bluetooth...")));
    }
    return;
  }
  if (await Permission.bluetoothConnect.isDenied ||
      await Permission.bluetoothConnect.isRestricted ||
      await Permission.bluetoothConnect.isPermanentlyDenied) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Nemáte povolený bluetooth (přístup k blízkým zařízením). Pro připojení k arduinu je potřeba povolení bluetooth...")));
    }
    return;
  }

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
    if (kDebugMode) {
      print('Connect -> no device selected');
    }
    return;
  }

  try {
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
      if (kDebugMode) {
        print('Connect -> no device selected');
      }
    }
  } catch (e) {
    //just ignore
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
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(overlayColor: MaterialStatePropertyAll(Colors.transparent)),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

Future<void> _sendPosData(BuildContext context, _MyHomePageState homepage) async {
  await Future.delayed(const Duration(seconds: 1));
  while (context.mounted) {
    await Future.delayed(const Duration(milliseconds: 50));
    if (connection != null && connection!.isConnected) {
      num speed = homepage._speed;
      num z = homepage.z;
      num direction = 0;
      if (homepage.steeringButtonsDissabled &&
          (z < (homepage._deadZone * pow(homepage._gyroSensitivity, 2)) && z > (-homepage._deadZone * pow(homepage._gyroSensitivity, 2)))) {
        direction = 0;
      } else if (homepage.steeringButtonsDissabled) {
        num gyroSensitivity = homepage._gyroSensitivity;
        gyroSensitivity = pow(gyroSensitivity, 2);
        speed = speed.clamp(-1, 1);
        z = z.clamp(gyroSensitivity * -1, gyroSensitivity);
        bool positive = z >= 0;
        direction = z.abs() / gyroSensitivity;
        direction = positive ? direction : direction * -1;
      } else {
        direction = homepage.buttonsZ;
      }
      direction *= -1; //we messed up the direction of the steering and don't want to rewrite it all so we just flip it here

      if (kDebugMode) {
        print("$speed|$direction");
      }
      send("$speed|$direction");
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // double x = 0, y = 0;
  double z = 0;
  double buttonsZ = 0;
  double rotationAngle = 0;
  double _speed = 0;
  double _deadZone = defaultDeadZone;
  double _gyroSensitivity = defaultGyroSensitivity;
  bool steeringButtonsDissabled = true;
  bool ableToDrive = false;

  double calculateAdjustedRotation(double z, double deadZone, double sensitivity) {
    if (z.abs() < deadZone) {
      return 0.0; // Within the deadzone
    } else {
      // Calculate the rotation angle based on sensitivity and quadratic graph
      double limitedRotation = z * -sensitivity * 45;
      return limitedRotation.clamp(-45, 45);
    }
  }

  @override
  void initState() {
    _sendPosData(context, this);
    gyroscopeEvents.listen((GyroscopeEvent event) {
      // x += event.x;
      // y += event.y;

      //rough calculation, you can use
      //advance formula to calculate the orentation
      if (!ableToDrive || !steeringButtonsDissabled) {
        z = 0;
        setState(() {});
        return;
      }
      z += event.z;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() async {
    BluetoothConnection? currentConnection = connection;
    connection = null;
    if (currentConnection != null) {
      await Future.delayed(const Duration(milliseconds: 150));
      await send("0.0|0.0", customConnection: currentConnection);
      await Future.delayed(const Duration(milliseconds: 50));
      currentConnection.dispose();
      return;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              var packageInfo = await PackageInfo.fromPlatform();
              if (!mounted) return;
              showAboutDialog(
                  context: context,
                  applicationName: "RC Auto Třebešín",
                  applicationLegalese: "© 2023 Tomáš Protiva a Matěj Verhaegen\nZveřejněno pod licencí MIT",
                  applicationVersion: packageInfo.version,
                  children: [
                    ElevatedButton(
                      onPressed: (() =>
                          launchUrl(Uri.parse("https://github.com/tpkowastaken/Trebesin-RC-Auto"), mode: LaunchMode.externalApplication)),
                      child: const Text("Zdrojový kód"),
                    )
                  ]);
            },
            icon: const Icon(Symbols.info_i_rounded),
          ),
          IconButton(
            icon: Icon(color: connection?.isConnected ?? false ? Colors.green : Colors.red, Symbols.bluetooth),
            onPressed: () {
              setState(() {
                ableToDrive = false;
              });
              bluetooth(context);
            },
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("RC Auto Ovladač"),
      ),
      body: Stack(
        children: [
          //arrow and settings
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 200), // Adjust animation duration as needed
                      tween: Tween<double>(
                        begin: rotationAngle,
                        end: calculateAdjustedRotation(z, _deadZone, _gyroSensitivity),
                      ),
                      builder: (context, value, child) {
                        if (steeringButtonsDissabled) {
                          rotationAngle = value;

                          return Transform.rotate(
                            angle: (value % 180) * (pi / 90), // Rotate exactly 90 degrees to each side
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 175.0, // Adjust the arrow size as needed
                            ),
                          );
                        } else {
                          value = buttonsZ;
                          return Transform.rotate(
                            angle: (value % 180) * (pi / 90), // Rotate exactly 90 degrees to each side
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 175.0, // Adjust the arrow size as needed
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Senzitivita: "),
                      SizedBox(
                        height: 20,
                        width: 200,
                        child: Slider.adaptive(
                          thumbColor: Theme.of(context).colorScheme.primary,
                          min: 0.1,
                          max: 3,
                          value: _gyroSensitivity,
                          onChanged: (value) {
                            setState(() {
                              _gyroSensitivity = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Velikost mrtvého bodu: "),
                      SizedBox(
                        width: 200,
                        height: 20,
                        child: Slider.adaptive(
                          thumbColor: Theme.of(context).colorScheme.primary,
                          divisions: 10,
                          min: 0,
                          max: 1,
                          value: _deadZone,
                          onChanged: (value) {
                            setState(() {
                              _deadZone = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          //button rail & speed slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //button rail
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
                          icon: Icon(
                            Symbols.power_settings_new,
                            size: 40,
                            color: ableToDrive ? Colors.green : Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _speed = 0;
                              ableToDrive = !ableToDrive;
                            });
                          },
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
                        //reset gyro 0-point
                        IconButton(
                          onPressed: () {
                            setState(() {
                              z = 0;
                            });
                          },
                          icon: const Icon(
                            Icons.auto_mode,
                            size: 40,
                          ),
                        ),
                        //reset gyro settings
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _gyroSensitivity = defaultGyroSensitivity;
                              _deadZone = defaultDeadZone;
                            });
                          },
                          icon: const Icon(
                            Symbols.manage_history,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //speed slider
              Stack(
                alignment: Alignment.center,
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.stat_3,
                        size: 100,
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
                        size: 100,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 200,
                    height: 230,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider.adaptive(
                        onChangeEnd: (_) => setState(() {
                          _speed = 0;
                          if (kDebugMode) {
                            print(_speed);
                          }
                        }),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        activeColor: Colors.transparent,
                        inactiveColor: Colors.transparent,
                        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
                        min: -1,
                        max: 1,
                        value: _speed,
                        onChanged: (value) {
                          if (ableToDrive) {
                            setState(() {
                              _speed = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          //steering Buttons
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: steeringButtonsDissabled || !ableToDrive
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
                            onTapDown: (details) {
                              setState(() {
                                buttonsZ = -45;
                              });
                            },
                            onTapUp: (details) {
                              setState(() {
                                buttonsZ = 0;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                buttonsZ = 0;
                              });
                            },
                            child: const Icon(
                              Symbols.arrow_circle_left_rounded,
                              size: 100,
                              color: Colors.black,
                            ),
                          ),
                          //steer right
                          GestureDetector(
                            onTapDown: (details) {
                              setState(() {
                                buttonsZ = 45;
                              });
                            },
                            onTapUp: (details) {
                              setState(() {
                                buttonsZ = 0;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                buttonsZ = 0;
                              });
                            },
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

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void bluetooth() async {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  flutterBlue.startScan(timeout: const Duration(seconds: 4));

  //Listen to scan results
  var subscription = flutterBlue.scanResults.listen((results) {
    // do something with scan results
    for (ScanResult r in results) {
      print('${r.device.name} found! rssi: ${r.rssi}');
    }
  });
  print(subscription);
}

void main() {
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: bluetooth,
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("RC Auto Ovladač"),
      ),
      body: Center(
        child: SizedBox(
          height: 300,
          width: 300,
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //left
                    MaterialButton(
                      shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                      padding: const EdgeInsets.all(0),
                      onPressed: () {},
                      child: const Icon(
                        Icons.arrow_circle_left_outlined,
                        size: 90,
                      ),
                    ),

                    //right
                    MaterialButton(
                      shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                      padding: const EdgeInsets.all(0),
                      onPressed: () {},
                      child: const Icon(
                        Icons.arrow_circle_right_outlined,
                        size: 90,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //up
                    MaterialButton(
                      shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                      padding: const EdgeInsets.all(0),
                      onPressed: () {},
                      child: const Icon(
                        Icons.arrow_circle_up,
                        size: 90,
                      ),
                    ),

                    //down

                    MaterialButton(
                      shape: const CircleBorder(side: BorderSide(color: Colors.transparent)),
                      padding: const EdgeInsets.all(0),
                      onPressed: () {},
                      child: const Icon(
                        Icons.arrow_circle_down,
                        size: 90,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

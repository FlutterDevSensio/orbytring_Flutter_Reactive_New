import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'DeviceScreen.dart';
import 'ble_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final BleController _controller = Get.put(BleController());

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.locationWhenInUse.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("BLE Scanner"),
            GestureDetector(
              onTap: () {
                print("Plot button tapped");
              },
              child: Icon(Icons.scatter_plot),
            ),
          ],
        ),
      ),
      body: GetBuilder<BleController>(
        init: BleController(),
        builder: (BleController controller) {
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<DiscoveredDevice>>(
                  stream: controller.scanResultsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data![index];
                          if (data.name.isEmpty) {
                            return SizedBox.shrink();
                          }
                          // return Card(
                          //   elevation: 2,
                          //   child: ListTile(
                          //     title: Text(data.name),
                          //     subtitle: Text(data.id),
                          //     trailing: ElevatedButton(
                          //       child: Text('CONNECT'),
                          //       onPressed: () async {
                          //         try {
                          //           await _ble
                          //               .connectToDevice(
                          //             id: data.id,
                          //             connectionTimeout: const Duration(seconds: 5),
                          //           )
                          //               .listen((connectionState) {
                          //             if (connectionState.connectionState ==
                          //                 DeviceConnectionState.connected) {
                          //               Navigator.of(context).push(
                          //                 MaterialPageRoute(
                          //                   builder: (context) => DeviceScreen(device: data),
                          //                 ),
                          //               );
                          //             }
                          //           }).asFuture();
                          //         } catch (e) {
                          //           print("Failed to connect: $e");
                          //         }
                          //       },
                          //     ),
                          //   ),
                          // );
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              title: Text(data.name),
                              subtitle: Text(data.id),
                              trailing: StreamBuilder<DeviceConnectionState>(
                                stream: _ble.connectedDeviceStream
                                    .where((event) => event.deviceId == data.id)
                                    .map((event) => event.connectionState),
                                initialData: DeviceConnectionState.disconnected,
                                builder: (context, snapshot) {
                                  if (snapshot.data == DeviceConnectionState.connected) {
                                    return ElevatedButton(
                                      child: Text('OPEN'),
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => DeviceScreen(device: data),
                                        ),
                                      ),
                                    );
                                  }
                                  return ElevatedButton(
                                    child: Text('CONNECT'),
                                    onPressed: () async {
                                      try {
                                        // Initiate the connection to the device
                                        _ble.connectToDevice(id: data.id).listen(
                                              (connectionState) {
                                            if (connectionState.connectionState == DeviceConnectionState.connected) {
                                              print("Connected to ${data.name}");
                                            }
                                          },
                                          onError: (e) {
                                            print("Failed to connect: $e");
                                          },
                                        );
                                      } catch (e) {
                                        print("Error during connection: $e");
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return Center(child: Text("No Devices found"));
                    }
                  },
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => controller.scanDevices(),
                child: Text("Scan"),
              ),
            ],
          );
        },
      ),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//   final BleController _controller = Get.put(BleController());
//
//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//   }
//
//   Future<void> _requestPermissions() async {
//     await Permission.locationWhenInUse.request();
//     await Permission.bluetoothScan.request();
//     await Permission.bluetoothConnect.request();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text("BLE Scanner"),
//             GestureDetector(
//               onTap: () {
//                 print("Plot button tapped");
//               },
//               child: Icon(Icons.scatter_plot),
//             ),
//           ],
//         ),
//       ),
//       body: GetBuilder<BleController>(
//         init: BleController(),
//         builder: (BleController controller) {
//           return Column(
//             children: [
//               Expanded(
//                 child: StreamBuilder<List<DiscoveredDevice>>(
//                   stream: controller.scanResults,
//                   builder: (context, snapshot) {
//                     if (snapshot.hasData && snapshot.data!.isNotEmpty) {
//                       return ListView.builder(
//                         itemCount: snapshot.data!.length,
//                         itemBuilder: (context, index) {
//                           final data = snapshot.data![index];
//                           if (data.name.isEmpty) {
//                             return SizedBox.shrink();
//                           }
//                           return Card(
//                             elevation: 2,
//                             child: ListTile(
//                               title: Text(data.name),
//                               subtitle: Text(data.id),
//                               trailing: ElevatedButton(
//                                 child: Text('CONNECT'),
//                                 onPressed: () async {
//                                   try {
//                                     await _ble.connectToDevice(
//                                       id: data.id,
//                                       connectionTimeout: const Duration(seconds: 5),
//                                     ).listen((connectionState) {
//                                       if (connectionState.connectionState ==
//                                           DeviceConnectionState.connected) {
//                                         Navigator.of(context).push(
//                                           MaterialPageRoute(
//                                             builder: (context) =>
//                                                 DeviceScreen(device: data),
//                                           ),
//                                         );
//                                       }
//                                     }).asFuture();
//                                   } catch (e) {
//                                     print("Failed to connect: $e");
//                                   }
//                                 },
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     } else {
//                       return Center(child: Text("No Devices found"));
//                     }
//                   },
//                 ),
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () => controller.scanDevices(),
//                 child: Text("Scan"),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
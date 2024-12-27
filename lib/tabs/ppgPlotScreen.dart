// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'dart:math' as math;
//
// class PlotData {
//   final int time;
//   final double value;
//
//   PlotData(this.time, this.value);
// }
//
// int _dataPointsPerSecond = 0;
//
// class PlotScreenPPG extends StatefulWidget {
//   final DiscoveredDevice device;
//   final List<DiscoveredService> services;
//
//   PlotScreenPPG({Key? key, required this.device, required this.services})
//       : super(key: key);
//
//   @override
//   _PlotScreenPPGState createState() => _PlotScreenPPGState();
// }
//
// class _PlotScreenPPGState extends State<PlotScreenPPG> {
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//   final TextEditingController _commandController = TextEditingController();
//   QualifiedCharacteristic? _notificationCharacteristic;
//   Map<Uuid, bool> _notificationStates = {};
//   int selectedValue = 100;
//
//   List<PlotData> redChannelData = [];
//   List<PlotData> irChannelData = [];
//   List<PlotData> greenChannelData = [];
//   int dataPointIndex = 0;
//
//   double _yAxisMin = 0;
//   double _yAxisMax = 1;
//
//   ZoomPanBehavior _zoomPanBehavior = ZoomPanBehavior(
//     enablePinching: true,
//     enablePanning: true,
//     enableDoubleTapZooming: true,
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     _connectToDevice();
//     _dataPointsPerSecond = 0;
//   }
//
//   Future<void> _connectToDevice() async {
//     try {
//       _ble.connectToDevice(id: widget.device.id).listen((connectionState) {
//         if (connectionState.connectionState ==
//             DeviceConnectionState.connected) {
//           _discoverServices();
//         }
//       }, onError: (e) {
//         print("Error connecting to device: $e");
//       });
//     } catch (e) {
//       print("Error connecting to device: $e");
//     }
//   }
//
//   // //
//   // Future<void> _discoverServices() async {
//   //   try {
//   //     final mtu = await _ble.requestMtu(deviceId: widget.device.id, mtu: 512);
//   //     print("MTU negotiated: $mtu");
//   //
//   //     final services = await _ble.discoverServices(widget.device.id);
//   //     for (var service in services) {
//   //       for (var characteristic in service.characteristics) {
//   //         if (characteristic.isNotifiable) {
//   //           _enableNotifications(characteristic);
//   //         }
//   //       }
//   //     }
//   //   } catch (e) {
//   //     print("Error discovering services: $e");
//   //   }
//   // }
//   // // // Future<void> _discoverServices() async {
//   // // //   try {
//   // // //     final mtu = await _ble.requestMtu(deviceId: widget.device.id, mtu: 512);
//   // // //     print("MTU negotiated: $mtu");
//   // // //     final services = await _ble.discoverServices(widget.device.id);
//   // // //     setState(() {
//   // // //       // _services = services;
//   // // //     });
//   // // //   } catch (e) {
//   // // //     print("Error discovering services: $e");
//   // // //   }
//   // // // }
//   // //
//   // // Future<void> _enableNotifications(QualifiedCharacteristic characteristic) async {
//   // //   try {
//   // //     _notificationCharacteristic = characteristic;
//   // //     _ble.subscribeToCharacteristic(characteristic).listen((value) {
//   // //       groupBytesIntoSamples(value);
//   // //     }, onError: (e) {
//   // //       print('Error receiving notifications: $e');
//   // //     });
//   // //     setState(() {
//   // //       _notificationStates[characteristic.characteristicId] = true;
//   // //     });
//   // //   } catch (e) {
//   // //     print('Error enabling notifications: $e');
//   // //   }
//   // // }
//   Future<void> _discoverServices() async {
//     try {
//       final mtu = await _ble.requestMtu(deviceId: widget.device.id, mtu: 512);
//       print("MTU negotiated: $mtu");
//
//       final services = await _ble.discoverServices(widget.device.id);
//       for (var service in services) {
//         for (var characteristic in service.characteristics) {
//           if (characteristic.isNotifiable) {
//             final qualifiedCharacteristic = QualifiedCharacteristic(
//               deviceId: widget.device.id,
//               serviceId: service.serviceId,
//               characteristicId: characteristic.characteristicId,
//             );
//             _enableNotifications(qualifiedCharacteristic);
//           }
//         }
//       }
//     } catch (e) {
//       print("Error discovering services: $e");
//     }
//   }
//
//   // Future<void> _enableNotifications(QualifiedCharacteristic characteristic) async {
//   //   try {
//   //
//   //     _ble.subscribeToCharacteristic(characteristic).listen((value) {
//   //       setState(() {
//   //         _notificationStates[characteristic.characteristicId] = true;
//   //       });
//   //       print('Notification received: $value');
//   //       groupBytesIntoSamples(value);
//   //
//   //
//   //     }, onError: (e) {
//   //       print('Error receiving notifications: $e');
//   //     });
//   //   } catch (e) {
//   //     print('Error enabling notifications: $e');
//   //   }
//   // }
//   Future<void> _enableNotifications(
//       QualifiedCharacteristic characteristic) async {
//     try {
//       _ble.subscribeToCharacteristic(characteristic).listen((value) {
//         print('Notification received: $value');
//         groupBytesIntoSamples(value);
//       }, onError: (e) {
//         print('Error receiving notifications: $e');
//       });
//       // Update the notification state
//       setState(() {
//         _notificationStates[characteristic.characteristicId] = true;
//       });
//     } catch (e) {
//       print('Error enabling notifications: $e');
//     }
//   }
//
//   void groupBytesIntoSamples(List<int> value) {
//     int sampleCount = value.length ~/ 3;
//     for (int i = 0; i < sampleCount; i++) {
//       int offset = i * 3;
//
//       int sample1 = value[offset];
//       int sample2 = value[offset + 1];
//       int sample3 = value[offset + 2];
//
//       int flag = sample1 >> 4;
//       int lowerNibble = sample1 & 0x0F;
//       int ppgData = (sample2 << 8) | sample3;
//       int finalData = (lowerNibble << 16) | ppgData;
//
//       if (flag == 0) {
//         redChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
//       } else if (flag == 1) {
//         irChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
//       } else if (flag == 2) {
//         greenChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
//       }
//
//       _updateYAxisRange(finalData.toDouble());
//     }
//   }
//
//   // void _updateYAxisRange(double newValue) {
//   //   setState(() {
//   //     _yAxisMin = greenChannelData.isEmpty
//   //         ? 0
//   //         : greenChannelData.map((data) => data.value).reduce(math.min);
//   //     _yAxisMax = greenChannelData.isEmpty
//   //         ? 1
//   //         : greenChannelData.map((data) => data.value).reduce(math.max);
//   //   });
//   // }
//   void _updateYAxisRange(double newValue) {
//     setState(() {
//       // Ensure the greenChannelData contains doubles
//       // final List<double> last1500Data = greenChannelData
//       //     .map((data) => data.value as double)
//       //     .toList()
//       //     .take(1500)
//       //     .toList();
//       final List<double> last1500Data = greenChannelData
//           .map((data) => data.value as double)
//           .toList()
//           .skip(
//           greenChannelData.length > 500 ? greenChannelData.length - 500 : 0)
//           .toList();
//
//       // Add the new value to the dataset
//       last1500Data.add(newValue);
//       print("Printing last 1500 data");
//       print(last1500Data);
//
//       // Calculate min and max for the Y-axis
//       _yAxisMin = last1500Data.isEmpty ? 0 : last1500Data.reduce(math.min);
//       print(_yAxisMin);
//       _yAxisMax = last1500Data.isEmpty ? 1 : last1500Data.reduce(math.max);
//       print(_yAxisMax);
//     });
//   }
//
//   void _zoomOut() {
//     setState(() {
//       _zoomPanBehavior.reset();
//       _yAxisMin = greenChannelData.isEmpty
//           ? 0
//           : greenChannelData.map((data) => data.value).reduce(math.min);
//       _yAxisMax = greenChannelData.isEmpty
//           ? 1
//           : greenChannelData.map((data) => data.value).reduce(math.max);
//     });
//   }
//
//   Future<void> _sendCommand(
//       QualifiedCharacteristic characteristic, String command) async {
//     print("Command sent: $command");
//     final bytes = command.codeUnits;
//     try {
//       await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);
//     } catch (e) {
//       print("Error sending command: $e");
//     }
//   }
//
//   Future<void> _disableNotifications(
//       QualifiedCharacteristic characteristic) async {
//     try {
//       await _ble
//           .writeCharacteristicWithoutResponse(characteristic, value: [0x00]);
//       _ble.subscribeToCharacteristic(characteristic).listen(null).cancel();
//       setState(() {
//         _notificationStates[characteristic.characteristicId] = false;
//       });
//       print('Notifications disabled for: ${characteristic.characteristicId}');
//     } catch (e) {
//       print('Error disabling notifications: $e');
//     }
//   }
//
//   List<Widget> _buildServiceTiles() {
//     return widget.services.map((service) {
//       if (service.serviceId.toString().toUpperCase() ==
//           '4E771A15-2665-CF92-8569-8C642A4AB357') {
//         return Column(
//           children: service.characteristics.map((characteristic) {
//             final qualifiedCharacteristic = QualifiedCharacteristic(
//               deviceId: widget.device.id,
//               serviceId: service.serviceId,
//               characteristicId: characteristic.characteristicId,
//             );
//             if (characteristic.characteristicId.toString().toUpperCase() ==
//                 '48837CB0-B733-7C24-31B7-222222222222') {
//               return Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (characteristic.isWritableWithResponse)
//                     IconButton(
//                       icon: Icon(Icons.send),
//                       onPressed: () async {
//                         _showCommandDialog(qualifiedCharacteristic);
//                       },
//                     ),
//                   if (characteristic.isNotifiable)
//                     IconButton(
//                       icon: Icon(
//                         (_notificationStates[characteristic.characteristicId] ??
//                             false)
//                             ? Icons.notifications
//                             : Icons.notifications_off,
//                       ),
//                       onPressed: () async {
//                         if (_notificationStates[
//                         characteristic.characteristicId] ==
//                             true) {
//                           print("we are gere");
//                           await _disableNotifications(qualifiedCharacteristic);
//                         } else {
//                           await _enableNotifications(qualifiedCharacteristic);
//                         }
//                       },
//                     ),
//                 ],
//               );
//             }
//             return SizedBox.shrink();
//           }).toList(),
//         );
//       }
//       return SizedBox.shrink();
//     }).toList();
//   }
//
//   void _showCommandDialog(QualifiedCharacteristic characteristic) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Send Command'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             DropdownButton<int>(
//               value: selectedValue,
//               onChanged: (int? newValue) {
//                 setState(() {
//                   selectedValue = newValue!;
//                   _commandController.text = 'STARTPPG:$selectedValue';
//                 });
//               },
//               items: [100, 200, 300, 400, 500].map<DropdownMenuItem<int>>(
//                     (int value) {
//                   return DropdownMenuItem<int>(
//                     value: value,
//                     child: Text(value.toString()),
//                   );
//                 },
//               ).toList(),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _commandController,
//               decoration: InputDecoration(hintText: 'Command will be sent'),
//               readOnly: true,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _commandController.clear();
//             },
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               String command = 'STARTPPG:$selectedValue';
//               _sendCommand(characteristic, command);
//               _commandController.clear();
//             },
//             child: Text('Send'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Real-time Green-Channel Data Plot"),
//         automaticallyImplyLeading: false,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.zoom_out),
//             onPressed: _zoomOut,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 6,
//             child: Column(
//               children: [
//                 Center(
//                   child:
//                   SfCartesianChart(
//                     zoomPanBehavior: _zoomPanBehavior,
//                     primaryXAxis: NumericAxis(
//                       title: AxisTitle(text: 'Time (Index)'),
//                       autoScrollingDelta: 1500,
//                       autoScrollingMode: AutoScrollingMode.end,
//                     ),
//                     primaryYAxis: NumericAxis(
//                       minimum: _yAxisMin,
//                       maximum: _yAxisMax,
//                     ),
//                     // series: <ChartSeries>[
//                     //   LineSeries<PlotData, int>(
//                     //     name: 'Green Channel',
//                     //     dataSource: greenChannelData,
//                     //     xValueMapper: (PlotData data, _) => data.time,
//                     //     yValueMapper: (PlotData data, _) => data.value,
//                     //   ),
//                     // ],
//                     series: <CartesianSeries>[
//                       FastLineSeries<PlotData, int>(
//                           name: 'Green Channel',
//                           dataSource: greenChannelData,
//                           xValueMapper: (PlotData data, _) => data.time,
//                           yValueMapper: (PlotData data, _) => data.value,
//                           animationDuration: 0,
//                           emptyPointSettings: EmptyPointSettings(
//                             mode: EmptyPointMode.average,)
//                       ),
//                       // FastLineSeries<PlotData, int>(
//                       //     name: 'Green Channel',
//                       //     dataSource: greenChannelData,
//                       //     xValueMapper: (PlotData data, _) => data.time,
//                       //     yValueMapper: (PlotData data, _) => data.value,
//                       //     animationDuration: 0,
//                       //     emptyPointSettings: EmptyPointSettings(
//                       //       mode: EmptyPointMode.average,)
//                       // ),
//
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: ListView(
//               children: _buildServiceTiles(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_blue/flutter_blue.dart';
// // import 'package:syncfusion_flutter_charts/charts.dart';
// // import 'dart:math' as math;
// //
// // class PlotData {
// //   final int time;
// //   final double value;
// //
// //   PlotData(this.time, this.value);
// // }
// //
// // int _dataPointsPerSecond = 0;
// //
// // class PlotScreenPPG extends StatefulWidget {
// //   final BluetoothDevice device;
// //   final List<BluetoothService> services;
// //
// //   PlotScreenPPG({Key? key, required this.device, required this.services})
// //       : super(key: key);
// //
// //   @override
// //   _PlotScreenPPGState createState() => _PlotScreenPPGState();
// // }
// //
// // class _PlotScreenPPGState extends State<PlotScreenPPG> {
// //   final TextEditingController _commandController = TextEditingController();
// //   BluetoothCharacteristic? _notificationCharacteristic;
// //   Map<Guid, bool> _notificationStates = {};
// //   int selectedValue = 100;
// //
// //   List<PlotData> redChannelData = [];
// //   List<PlotData> irChannelData = [];
// //   List<PlotData> greenChannelData = [];
// //   int dataPointIndex = 0;
// //
// //   List<int> channel1 = [];
// //   List<int> channel2 = [];
// //   List<int> channel3 = [];
// //
// //   double _yAxisMin = 0;
// //   double _yAxisMax = 1;
// //
// //   ZoomPanBehavior _zoomPanBehavior = ZoomPanBehavior(
// //     enablePinching: true,
// //     enablePanning: true,
// //     enableDoubleTapZooming: true,
// //
// //   );
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     widget.device.requestMtu(512);
// //     _connectToDevice();
// //     _dataPointsPerSecond = 0;
// //   }
// //
// //   Future<void> _connectToDevice() async {
// //     try {
// //       await widget.device.connect();
// //       print("Connected to device: ${widget.device.name}");
// //
// //       List<BluetoothService> services = await widget.device.discoverServices();
// //       for (var service in services) {
// //         for (var characteristic in service.characteristics) {
// //           if (characteristic.properties.notify) {
// //             _enableNotifications(characteristic);
// //           }
// //         }
// //       }
// //     } catch (e) {
// //       print("Error connecting to device: $e");
// //     }
// //   }
// //
// //   Future<void> _enableNotifications(
// //       BluetoothCharacteristic characteristic) async {
// //     try {
// //       await characteristic.setNotifyValue(true);
// //       _notificationCharacteristic = characteristic;
// //       _notificationCharacteristic?.value.listen((value) {
// //         groupBytesIntoSamples(value);
// //       });
// //     } catch (e) {
// //       print('Error enabling notifications: $e');
// //     }
// //   }
// //
// //   void groupBytesIntoSamples(List<int> value) {
// //     int sampleCount = value.length ~/ 3;
// //     for (int i = 0; i < sampleCount; i++) {
// //       int offset = i * 3;
// //
// //       int sample1 = value[offset];
// //       int sample2 = value[offset + 1];
// //       int sample3 = value[offset + 2];
// //
// //       int flag = sample1 >> 4;
// //       int lowerNibble = sample1 & 0x0F;
// //       int ppgData = (sample2 << 8) | sample3;
// //       int finalData = (lowerNibble << 16) | ppgData;
// //
// //       if (flag == 0) {
// //         redChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
// //       } else if (flag == 1) {
// //         irChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
// //       } else if (flag == 2) {
// //         greenChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
// //       }
// //
// //       _updateYAxisRange(finalData.toDouble());
// //     }
// //   }
// //
// //   void _updateYAxisRange(double newValue) {
// //     setState(() {
// //       _yAxisMin = greenChannelData.isEmpty
// //           ? 0
// //           : greenChannelData.map((data) => data.value).reduce(math.min);
// //       _yAxisMax = greenChannelData.isEmpty
// //           ? 1
// //           : greenChannelData.map((data) => data.value).reduce(math.max);
// //     });
// //   }
// //
// //   void _zoomOut() {
// //     setState(() {
// //       _zoomPanBehavior.reset();
// //     });
// //   }
// //
// //   Future<void> _sendCommand(
// //       BluetoothCharacteristic characteristic, String command) async {
// //     print("Command sent: $command");
// //     List<int> bytes = command.codeUnits;
// //     await characteristic.write(bytes, withoutResponse: false);
// //     print("Command sent: $command");
// //   }
// //
// //   Future<void> _disableNotifications(
// //       BluetoothCharacteristic characteristic) async {
// //     try {
// //       await characteristic.setNotifyValue(false);
// //     } catch (e) {
// //       print('Error disabling notifications: $e');
// //     }
// //   }
// //   List<Widget> _buildServiceTiles() {
// //     return widget.services.map((service) {
// //       if (service.uuid.toString().toUpperCase() ==
// //           '4E771A15-2665-CF92-8569-8C642A4AB357') {
// //         return Column(
// //           children: service.characteristics.map((characteristic) {
// //             if (characteristic.uuid.toString().toUpperCase() ==
// //                 '48837CB0-B733-7C24-31B7-222222222222') {
// //               return Row(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   if (characteristic.properties.write)
// //                     IconButton(
// //                       icon: Icon(Icons.send),
// //                       onPressed: () async {
// //                         _showCommandDialog(characteristic);
// //                       },
// //                     ),
// //                   if (characteristic.properties.notify ||
// //                       characteristic.properties.indicate)
// //                     IconButton(
// //                       icon: Icon(
// //                         (_notificationStates[characteristic.uuid] ?? false)
// //                             ? Icons.notifications
// //                             : Icons.notifications_off,
// //                       ),
// //                       onPressed: () async {
// //                         if (_notificationStates[characteristic.uuid] == true) {
// //                           await _disableNotifications(characteristic);
// //                         } else {
// //                           await _enableNotifications(characteristic);
// //                         }
// //                         setState(() {
// //                           _notificationStates[characteristic.uuid] =
// //                           !(_notificationStates[characteristic.uuid] ?? false);
// //                         });
// //                       },
// //                     ),
// //                 ],
// //               );
// //             }
// //             return SizedBox.shrink();
// //           }).toList(),
// //         );
// //       }
// //       return SizedBox.shrink();
// //     }).toList();
// //   }
// //
// //   // List<Widget> _buildServiceTiles() {
// //   //   return widget.services.map((service) {
// //   //     if (service.uuid.toString().toUpperCase() ==
// //   //         '4E771A15-2665-CF92-8569-8C642A4AB357') {
// //   //       return ExpansionTile(
// //   //         title: Text('Service: ${service.uuid.toString().toUpperCase()}'),
// //   //         children: service.characteristics.map((characteristic) {
// //   //           if (characteristic.uuid.toString().toUpperCase() ==
// //   //               '48837CB0-B733-7C24-31B7-222222222222') {
// //   //             return ListTile(
// //   //               title: Text(
// //   //                   'Characteristic: ${characteristic.uuid.toString().toUpperCase()}'),
// //   //               trailing: Row(
// //   //                 mainAxisSize: MainAxisSize.min,
// //   //                 children: [
// //   //                   if (characteristic.properties.write)
// //   //                     IconButton(
// //   //                       icon: Icon(Icons.send),
// //   //                       onPressed: () async {
// //   //                         if (characteristic.properties.write) {
// //   //                           _showCommandDialog(characteristic);
// //   //                         }
// //   //                       },
// //   //                     ),
// //   //                   if (characteristic.properties.notify ||
// //   //                       characteristic.properties.indicate)
// //   //                     IconButton(
// //   //                       icon: Icon(
// //   //                         (_notificationStates[characteristic.uuid] ?? false)
// //   //                             ? Icons.notifications
// //   //                             : Icons.notifications_off,
// //   //                       ),
// //   //                       onPressed: () async {
// //   //                         if (_notificationStates[characteristic.uuid] ==
// //   //                             true) {
// //   //                           await _disableNotifications(characteristic);
// //   //                         } else {
// //   //                           await _enableNotifications(characteristic);
// //   //                         }
// //   //                         setState(() {
// //   //                           _notificationStates[characteristic.uuid] =
// //   //                           !(_notificationStates[characteristic.uuid] ??
// //   //                               false);
// //   //                         });
// //   //                       },
// //   //                     ),
// //   //                 ],
// //   //               ),
// //   //             );
// //   //           }
// //   //           return Container();
// //   //         }).toList(),
// //   //       );
// //   //     }
// //   //     return SizedBox.shrink();
// //   //   }).toList();
// //   // }
// //
// //   void _showCommandDialog(BluetoothCharacteristic characteristic) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text('Send Command'),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             DropdownButton<int>(
// //               value: selectedValue,
// //               onChanged: (int? newValue) {
// //                 setState(() {
// //                   selectedValue = newValue!;
// //                   _commandController.text = 'STARTPPG:$selectedValue';
// //                 });
// //               },
// //               items: [100, 200, 300, 400, 500].map<DropdownMenuItem<int>>(
// //                     (int value) {
// //                   return DropdownMenuItem<int>(
// //                     value: value,
// //                     child: Text(value.toString()),
// //                   );
// //                 },
// //               ).toList(),
// //             ),
// //             SizedBox(height: 16),
// //             TextField(
// //               controller: _commandController,
// //               decoration: InputDecoration(hintText: 'Command will be sent'),
// //               readOnly: true,
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               _commandController.clear();
// //             },
// //             child: Text('Cancel'),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               String command = 'STARTPPG:$selectedValue';
// //               _sendCommand(characteristic, command);
// //               _commandController.clear();
// //             },
// //             child: Text('Send'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     int n = greenChannelData.length;
// //     for (int i = 0; i < n; i++) {
// //       print(greenChannelData[i].value);
// //     }
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text("Real-time Green-Channel Data Plot"),
// //         automaticallyImplyLeading: false,
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.zoom_out),
// //             onPressed: _zoomOut,
// //           ),
// //         ],
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             flex:6,
// //             child: Center(
// //               child: SfCartesianChart(
// //                 zoomPanBehavior: _zoomPanBehavior,
// //                 primaryXAxis: NumericAxis(
// //                   title: AxisTitle(text: 'Time (Index)'),
// //                   autoScrollingDelta: 1500,
// //                   autoScrollingMode: AutoScrollingMode.end,
// //                 ),
// //                 primaryYAxis: NumericAxis(
// //                   // title: AxisTitle(text: 'Value'),
// //                   minimum: _yAxisMin,
// //                   maximum: _yAxisMax,
// //                 ),
// //                 series: <ChartSeries>[
// //                   LineSeries<PlotData, int>(
// //                     name: 'Green Channel',
// //                     dataSource: greenChannelData,
// //                     xValueMapper: (PlotData data, _) => data.time,
// //                     yValueMapper: (PlotData data, _) => data.value,
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 1,
// //             child: ListView(
// //               children: _buildServiceTiles(),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'dart:math' as math;
//
// class PlotData {
//   final int time;
//   final double value;
//
//   PlotData(this.time, this.value);
// }
//
// int _dataPointsPerSecond = 0;
//
// class PlotScreenPPG extends StatefulWidget {
//   final DiscoveredDevice device;
//   // final List<Service> services;
//   final List<DiscoveredService> services;
//   PlotScreenPPG({Key? key, required this.device, required this.services})
//       : super(key: key);
//
//   @override
//   _PlotScreenPPGState createState() => _PlotScreenPPGState();
// }
//
// class _PlotScreenPPGState extends State<PlotScreenPPG> {
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//   final TextEditingController _commandController = TextEditingController();
//   int selectedValue = 100;
//
//   List<PlotData> redChannelData = [];
//   List<PlotData> irChannelData = [];
//   List<PlotData> greenChannelData = [];
//   int dataPointIndex = 0;
//
//   double _yAxisMin = 0;
//   double _yAxisMax = 1;
//
//   ZoomPanBehavior _zoomPanBehavior = ZoomPanBehavior(
//     enablePinching: true,
//     enablePanning: true,
//     enableDoubleTapZooming: true,
//   );
//
//   Map<String, bool> _notificationStates = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _connectToDevice();
//     _dataPointsPerSecond = 0;
//   }
//
//   Future<void> _connectToDevice() async {
//     try {
//       _ble.connectToDevice(id: widget.device.id).listen((connectionState) {
//         if (connectionState.connectionState == DeviceConnectionState.connected) {
//           _discoverServices();
//         }
//       });
//     } catch (e) {
//       print("Error connecting to device: $e");
//     }
//   }
//
//   Future<void> _discoverServices() async {
//     try {
//       final services = await _ble.discoverServices(widget.device.id);
//       for (final service in services) {
//         for (final characteristic in service.characteristics) {
//           if (characteristic.isNotifiable) {
//             _enableNotifications(characteristic);
//           }
//         }
//       }
//     } catch (e) {
//       print("Error discovering services: $e");
//     }
//   }
//
//   Future<void> _enableNotifications(DiscoveredCharacteristic characteristic) async {
//     final qualifiedCharacteristic = QualifiedCharacteristic(
//       characteristicId: characteristic.characteristicId,
//       serviceId: characteristic.serviceId,
//       deviceId: widget.device.id,
//     );
//
//     try {
//       _ble.subscribeToCharacteristic(qualifiedCharacteristic).listen((value) {
//         groupBytesIntoSamples(value);
//       });
//       setState(() => _notificationStates[characteristic.characteristicId.toString()] = true);
//     } catch (e) {
//       print('Error enabling notifications: $e');
//     }
//   }
//
//   void groupBytesIntoSamples(List<int> value) {
//     int sampleCount = value.length ~/ 3;
//     for (int i = 0; i < sampleCount; i++) {
//       int offset = i * 3;
//
//       int sample1 = value[offset];
//       int sample2 = value[offset + 1];
//       int sample3 = value[offset + 2];
//
//       int flag = sample1 >> 4;
//       int lowerNibble = sample1 & 0x0F;
//       int ppgData = (sample2 << 8) | sample3;
//       int finalData = (lowerNibble << 16) | ppgData;
//
//       if (flag == 0) {
//         redChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
//       } else if (flag == 1) {
//         irChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
//       } else if (flag == 2) {
//         greenChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
//       }
//
//       _updateYAxisRange(finalData.toDouble());
//     }
//   }
//
//   void _updateYAxisRange(double newValue) {
//     setState(() {
//       _yAxisMin = greenChannelData.isEmpty
//           ? 0
//           : greenChannelData.map((data) => data.value).reduce(math.min);
//       _yAxisMax = greenChannelData.isEmpty
//           ? 1
//           : greenChannelData.map((data) => data.value).reduce(math.max);
//     });
//   }
//
//   void _zoomOut() {
//     setState(() {
//       _zoomPanBehavior.reset();
//     });
//   }
//
//   Future<void> _sendCommand(QualifiedCharacteristic characteristic, String command) async {
//     try {
//       await _ble.writeCharacteristicWithResponse(characteristic, value: command.codeUnits);
//       print('Command sent: $command');
//     } catch (e) {
//       print('Error sending command: $e');
//     }
//   }
//
//   Future<void> _disableNotifications(DiscoveredCharacteristic characteristic) async {
//     final qualifiedCharacteristic = QualifiedCharacteristic(
//       characteristicId: characteristic.characteristicId,
//       serviceId: characteristic.serviceId,
//       deviceId: widget.device.id,
//     );
//
//     setState(() => _notificationStates[characteristic.characteristicId.toString()] = false);
//   }
//
//   List<Widget> _buildServiceTiles() {
//     return widget.services.map((service) {
//       return Column(
//         children: service.characteristics.map((characteristic) {
//           final charId = characteristic.characteristicId.toString();
//           return Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (characteristic.isWritableWithResponse)
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: () async {
//                     _showCommandDialog(characteristic);
//                   },
//                 ),
//               if (characteristic.isNotifiable)
//                 IconButton(
//                   icon: Icon(
//                     (_notificationStates[charId] ?? false)
//                         ? Icons.notifications
//                         : Icons.notifications_off,
//                   ),
//                   onPressed: () async {
//                     if (_notificationStates[charId] == true) {
//                       await _disableNotifications(characteristic);
//                     } else {
//                       await _enableNotifications(characteristic);
//                     }
//                   },
//                 ),
//             ],
//           );
//         }).toList(),
//       );
//     }).toList();
//   }
//
//   void _showCommandDialog(DiscoveredCharacteristic characteristic) {
//     final qualifiedCharacteristic = QualifiedCharacteristic(
//       characteristicId: characteristic.characteristicId,
//       serviceId: characteristic.serviceId,
//       deviceId: widget.device.id,
//     );
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Send Command'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             DropdownButton<int>(
//               value: selectedValue,
//               onChanged: (int? newValue) {
//                 setState(() {
//                   selectedValue = newValue!;
//                   _commandController.text = 'STARTPPG:$selectedValue';
//                 });
//               },
//               items: [100, 200, 300, 400, 500]
//                   .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
//                   .toList(),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _commandController,
//               decoration: InputDecoration(hintText: 'Command will be sent'),
//               readOnly: true,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _commandController.clear();
//             },
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               final command = _commandController.text;
//               _sendCommand(qualifiedCharacteristic, command);
//               _commandController.clear();
//             },
//             child: Text('Send'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Real-time Green-Channel Data Plot"),
//         automaticallyImplyLeading: false,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.zoom_out),
//             onPressed: _zoomOut,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 6,
//             child: Center(
//               child: SfCartesianChart(
//                 zoomPanBehavior: _zoomPanBehavior,
//                 primaryXAxis: NumericAxis(
//                   title: AxisTitle(text: 'Time (Index)'),
//                   autoScrollingDelta: 1500,
//                   autoScrollingMode: AutoScrollingMode.end,
//                 ),
//                 primaryYAxis: NumericAxis(
//                   minimum: _yAxisMin,
//                   maximum: _yAxisMax,
//                 ),
//                 series: <CartesianSeries>[
//                   LineSeries<PlotData, int>(
//                     name: 'Green Channel',
//                     dataSource: greenChannelData,
//                     xValueMapper: (PlotData data, _) => data.time,
//                     yValueMapper: (PlotData data, _) => data.value,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: ListView(
//               children: _buildServiceTiles(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;

class PlotData {
  final int time;
  final double value;

  PlotData(this.time, this.value);
}

int _dataPointsPerSecond = 0;

class PlotScreenPPG extends StatefulWidget {
  final DiscoveredDevice device;
  final List<DiscoveredService> services;

  const PlotScreenPPG(
      {super.key, required this.device, required this.services});

  @override
  _PlotScreenPPGState createState() => _PlotScreenPPGState();
}

class _PlotScreenPPGState extends State<PlotScreenPPG> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final TextEditingController _commandController = TextEditingController();
  QualifiedCharacteristic? _notificationCharacteristic;
  final Map<Uuid, bool> _notificationStates = {};
  int selectedValue = 100;

  List<PlotData> redChannelData = [];
  List<PlotData> irChannelData = [];
  List<PlotData> greenChannelData = [];
  int dataPointIndex = 0;

  double _yAxisMin = 0;
  double _yAxisMax = 1;
  final ZoomPanBehavior _redZoomPanBehavior = ZoomPanBehavior(
    enablePinching: true,
    enablePanning: true,
    enableDoubleTapZooming: true,
  );

  final ZoomPanBehavior _irZoomPanBehavior = ZoomPanBehavior(
    enablePinching: true,
    enablePanning: true,
    enableDoubleTapZooming: true,
  );

  final ZoomPanBehavior _greenZoomPanBehavior = ZoomPanBehavior(
    enablePinching: true,
    enablePanning: true,
    enableDoubleTapZooming: true,
  );
  final ZoomPanBehavior _zoomPanBehavior = ZoomPanBehavior(
    enablePinching: true,
    enablePanning: true,
    enableDoubleTapZooming: true,
  );

  @override
  void initState() {
    super.initState();
    _connectToDevice();
    _dataPointsPerSecond = 0;
  }

  double _redYAxisMin = 0, _redYAxisMax = 1;
  double _irYAxisMin = 0, _irYAxisMax = 1;
  double _greenYAxisMin = 0, _greenYAxisMax = 1;

  void _updateRedYAxisRange(double newValue) {
    setState(() {
      final lastData = redChannelData
          .skip(redChannelData.length > 500 ? redChannelData.length - 500 : 0);
      final values = lastData.map((data) => data.value).toList();
      _redYAxisMin = values.isEmpty ? 0 : values.reduce(math.min);
      _redYAxisMax = values.isEmpty ? 1 : values.reduce(math.max);
    });
  }

  void _updateIRYAxisRange(double newValue) {
    setState(() {
      final lastData = irChannelData
          .skip(irChannelData.length > 500 ? irChannelData.length - 500 : 0);
      final values = lastData.map((data) => data.value).toList();
      _irYAxisMin = values.isEmpty ? 0 : values.reduce(math.min);
      _irYAxisMax = values.isEmpty ? 1 : values.reduce(math.max);
    });
  }

  void _updateGreenYAxisRange(double newValue) {
    setState(() {
      final lastData = greenChannelData.skip(
          greenChannelData.length > 500 ? greenChannelData.length - 500 : 0);
      final values = lastData.map((data) => data.value).toList();
      _greenYAxisMin = values.isEmpty ? 0 : values.reduce(math.min);
      _greenYAxisMax = values.isEmpty ? 1 : values.reduce(math.max);
    });
  }

  Future<void> _connectToDevice() async {
    try {
      _ble.connectToDevice(id: widget.device.id).listen((connectionState) {
        if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          _discoverServices();
        }
      }, onError: (e) {
        print("Error connecting to device: $e");
      });
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

  // //
  // Future<void> _discoverServices() async {
  //   try {
  //     final mtu = await _ble.requestMtu(deviceId: widget.device.id, mtu: 512);
  //     print("MTU negotiated: $mtu");
  //
  //     final services = await _ble.discoverServices(widget.device.id);
  //     for (var service in services) {
  //       for (var characteristic in service.characteristics) {
  //         if (characteristic.isNotifiable) {
  //           _enableNotifications(characteristic);
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print("Error discovering services: $e");
  //   }
  // }
  // // // Future<void> _discoverServices() async {
  // // //   try {
  // // //     final mtu = await _ble.requestMtu(deviceId: widget.device.id, mtu: 512);
  // // //     print("MTU negotiated: $mtu");
  // // //     final services = await _ble.discoverServices(widget.device.id);
  // // //     setState(() {
  // // //       // _services = services;
  // // //     });
  // // //   } catch (e) {
  // // //     print("Error discovering services: $e");
  // // //   }
  // // // }
  // //
  // // Future<void> _enableNotifications(QualifiedCharacteristic characteristic) async {
  // //   try {
  // //     _notificationCharacteristic = characteristic;
  // //     _ble.subscribeToCharacteristic(characteristic).listen((value) {
  // //       groupBytesIntoSamples(value);
  // //     }, onError: (e) {
  // //       print('Error receiving notifications: $e');
  // //     });
  // //     setState(() {
  // //       _notificationStates[characteristic.characteristicId] = true;
  // //     });
  // //   } catch (e) {
  // //     print('Error enabling notifications: $e');
  // //   }
  // // }
  Future<void> _discoverServices() async {
    try {
      final mtu = await _ble.requestMtu(deviceId: widget.device.id, mtu: 512);
      print("MTU negotiated: $mtu");

      final services = await _ble.discoverServices(widget.device.id);
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.isNotifiable) {
            final qualifiedCharacteristic = QualifiedCharacteristic(
              deviceId: widget.device.id,
              serviceId: service.serviceId,
              characteristicId: characteristic.characteristicId,
            );
            _enableNotifications(qualifiedCharacteristic);
          }
        }
      }
    } catch (e) {
      print("Error discovering services: $e");
    }
  }

  // Future<void> _enableNotifications(QualifiedCharacteristic characteristic) async {
  //   try {
  //
  //     _ble.subscribeToCharacteristic(characteristic).listen((value) {
  //       setState(() {
  //         _notificationStates[characteristic.characteristicId] = true;
  //       });
  //       print('Notification received: $value');
  //       groupBytesIntoSamples(value);
  //
  //
  //     }, onError: (e) {
  //       print('Error receiving notifications: $e');
  //     });
  //   } catch (e) {
  //     print('Error enabling notifications: $e');
  //   }
  // }
  Future<void> _enableNotifications(
      QualifiedCharacteristic characteristic) async {
    try {
      _ble.subscribeToCharacteristic(characteristic).listen((value) {
        print('Notification received: $value');
        groupBytesIntoSamples(value);
      }, onError: (e) {
        print('Error receiving notifications: $e');
      });
      // Update the notification state
      setState(() {
        _notificationStates[characteristic.characteristicId] = true;
      });
    } catch (e) {
      print('Error enabling notifications: $e');
    }
  }

  void groupBytesIntoSamples(List<int> value) {
    int sampleCount = value.length ~/ 3;
    for (int i = 0; i < sampleCount; i++) {
      int offset = i * 3;

      int sample1 = value[offset];
      int sample2 = value[offset + 1];
      int sample3 = value[offset + 2];

      int flag = sample1 >> 4;
      int lowerNibble = sample1 & 0x0F;
      int ppgData = (sample2 << 8) | sample3;
      int finalData = (lowerNibble << 16) | ppgData;

      if (flag == 0) {
        redChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
      } else if (flag == 1) {
        irChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
      } else if (flag == 2) {
        greenChannelData.add(PlotData(dataPointIndex++, finalData.toDouble()));
      }
      _updateRedYAxisRange(finalData.toDouble());
      _updateIRYAxisRange(finalData.toDouble());
      _updateGreenYAxisRange(finalData.toDouble());
      _updateYAxisRange(finalData.toDouble());
    }
  }

  // void _updateYAxisRange(double newValue) {
  //   setState(() {
  //     _yAxisMin = greenChannelData.isEmpty
  //         ? 0
  //         : greenChannelData.map((data) => data.value).reduce(math.min);
  //     _yAxisMax = greenChannelData.isEmpty
  //         ? 1
  //         : greenChannelData.map((data) => data.value).reduce(math.max);
  //   });
  // }
  void _updateYAxisRange(double newValue) {
    setState(() {
      // Ensure the greenChannelData contains doubles
      // final List<double> last1500Data = greenChannelData
      //     .map((data) => data.value as double)
      //     .toList()
      //     .take(1500)
      //     .toList();
      final List<double> last1500Data = greenChannelData
          .map((data) => data.value)
          .toList()
          .skip(
          greenChannelData.length > 500 ? greenChannelData.length - 500 : 0)
          .toList();

      // Add the new value to the dataset
      last1500Data.add(newValue);
      print("Printing last 1500 data");
      print(last1500Data);

      // Calculate min and max for the Y-axis
      _yAxisMin = last1500Data.isEmpty ? 0 : last1500Data.reduce(math.min);
      print(_yAxisMin);
      _yAxisMax = last1500Data.isEmpty ? 1 : last1500Data.reduce(math.max);
      print(_yAxisMax);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomPanBehavior.reset();
      _yAxisMin = greenChannelData.isEmpty
          ? 0
          : greenChannelData.map((data) => data.value).reduce(math.min);
      _yAxisMax = greenChannelData.isEmpty
          ? 1
          : greenChannelData.map((data) => data.value).reduce(math.max);
    });
  }

  Future<void> _sendCommand(
      QualifiedCharacteristic characteristic, String command) async {
    print("Command sent: $command");
    final bytes = command.codeUnits;
    try {
      await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  Future<void> _disableNotifications(
      QualifiedCharacteristic characteristic) async {
    try {
      _sendCommand(characteristic, "STOPPPG");
      // await _ble
      //     .writeCharacteristicWithoutResponse(characteristic, value: [0x00]);
      // _ble.subscribeToCharacteristic(characteristic).listen(null).cancel();
      setState(() {
        _notificationStates[characteristic.characteristicId] = false;
      });
      print('Notifications disabled for: ${characteristic.characteristicId}');
    } catch (e) {
      print('Error disabling notifications: $e');
    }
  }

  List<Widget> _buildServiceTiles() {
    return widget.services.map((service) {
      if (service.serviceId.toString().toUpperCase() ==
          '4E771A15-2665-CF92-8569-8C642A4AB357') {
        return Column(
          children: service.characteristics.map((characteristic) {
            final qualifiedCharacteristic = QualifiedCharacteristic(
              deviceId: widget.device.id,
              serviceId: service.serviceId,
              characteristicId: characteristic.characteristicId,
            );
            if (characteristic.characteristicId.toString().toUpperCase() ==
                '48837CB0-B733-7C24-31B7-222222222222') {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (characteristic.isWritableWithResponse)
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        _showCommandDialog(qualifiedCharacteristic);
                      },
                    ),
                  if (characteristic.isNotifiable)
                    IconButton(
                      icon: Icon(
                        (_notificationStates[characteristic.characteristicId] ??
                            false)
                            ? Icons.notifications
                            : Icons.notifications_off,
                      ),
                      onPressed: () async {
                        if (_notificationStates[
                        characteristic.characteristicId] ==
                            true) {
                          print("we are gere");
                          await _disableNotifications(qualifiedCharacteristic);
                        } else {
                          await _enableNotifications(qualifiedCharacteristic);
                        }
                      },
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }

  void _showCommandDialog(QualifiedCharacteristic characteristic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Command'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: selectedValue,
              onChanged: (int? newValue) {
                setState(() {
                  selectedValue = newValue!;
                  _commandController.text = 'STARTPPG:$selectedValue';
                });
              },
              items: [100, 200, 300, 400, 500].map<DropdownMenuItem<int>>(
                    (int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commandController,
              decoration:
              const InputDecoration(hintText: 'Command will be sent'),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _commandController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              String command = 'STARTPPG:$selectedValue';
              _sendCommand(characteristic, command);
              _commandController.clear();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Real-timeData Plot"),
      //   automaticallyImplyLeading: false,
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.zoom_out),
      //       onPressed: _zoomOut,
      //     ),
      //   ],
      // ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Red Channel Chart - Collapsible
                    ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Red Channel',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.zoom_out),
                            color: Colors.red,
                            onPressed: () {
                              setState(() {
                                // _redYAxisMin = redChannelData.isEmpty
                                //     ? 0
                                //     : redChannelData.map((data) => data.value).reduce(math.min);
                                // _redYAxisMax = redChannelData.isEmpty
                                //     ? 1
                                //     : redChannelData.map((data) => data.value).reduce(math.max);
                                // _redZoomPanBehavior.reset();
                                // _zoomPanBehavior.reset();
                                _redYAxisMin = greenChannelData.isEmpty
                                    ? 0
                                    : greenChannelData
                                    .map((data) => data.value)
                                    .reduce(math.min);
                                _redYAxisMax = greenChannelData.isEmpty
                                    ? 1
                                    : greenChannelData
                                    .map((data) => data.value)
                                    .reduce(math.max);
                                _redZoomPanBehavior.reset();
                              });
                            },
                          ),
                        ],
                      ),
                      // Text(
                      //   'Red Channel',
                      //   style: TextStyle(
                      //       fontSize: 18,
                      //       color: Colors.red,
                      //       fontWeight: FontWeight.bold),
                      // ),
                      children: [
                        // IconButton(
                        //   icon: Icon(Icons.zoom_out),
                        //   color: Colors.red,
                        //   onPressed: () {
                        //     setState(() {
                        //       _redYAxisMin = redChannelData.isEmpty
                        //           ? 0
                        //           : redChannelData.map((data) => data.value).reduce(math.min);
                        //       _redYAxisMax = redChannelData.isEmpty
                        //           ? 1
                        //           : redChannelData.map((data) => data.value).reduce(math.max);
                        //       _zoomPanBehavior.reset();
                        //     });
                        //   },
                        // ),

                        SizedBox(
                          height: 300, // Adjust height as needed
                          child: SfCartesianChart(
                            // zoomPanBehavior: _zoomPanBehavior,
                            zoomPanBehavior: _redZoomPanBehavior,
                            primaryXAxis: NumericAxis(
                              title: AxisTitle(text: 'Time (Index)'),
                              autoScrollingDelta: 1500,
                              autoScrollingMode: AutoScrollingMode.end,
                            ),
                            primaryYAxis: NumericAxis(
                              minimum: _redYAxisMin,
                              maximum: _redYAxisMax,
                              // minimum: _yAxisMin,
                              // maximum: _yAxisMax,
                            ),
                            series: <CartesianSeries>[
                              FastLineSeries<PlotData, int>(
                                name: 'Red Channel',
                                dataSource: redChannelData,
                                xValueMapper: (PlotData data, _) => data.time,
                                yValueMapper: (PlotData data, _) => data.value,
                                animationDuration: 0,
                                emptyPointSettings: EmptyPointSettings(
                                  mode: EmptyPointMode.average,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // IR Channel Chart - Collapsible
                    ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'IR Channel',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.zoom_out),
                            // color: Colors.green,
                            onPressed: () {
                              setState(() {
                                // _redYAxisMin = redChannelData.isEmpty
                                //     ? 0
                                //     : redChannelData.map((data) => data.value).reduce(math.min);
                                // _redYAxisMax = redChannelData.isEmpty
                                //     ? 1
                                //     : redChannelData.map((data) => data.value).reduce(math.max);
                                // _zoomPanBehavior.reset();
                                // _irZoomPanBehavior.reset();
                                _irYAxisMin = greenChannelData.isEmpty
                                    ? 0
                                    : greenChannelData
                                    .map((data) => data.value)
                                    .reduce(math.min);
                                _irYAxisMax = greenChannelData.isEmpty
                                    ? 1
                                    : greenChannelData
                                    .map((data) => data.value)
                                    .reduce(math.max);
                                _irZoomPanBehavior.reset();
                              });
                            },
                          ),
                        ],
                      ),
                      children: [
                        SizedBox(
                          height: 300, // Adjust height as needed
                          child: SfCartesianChart(
                            // zoomPanBehavior: _zoomPanBehavior,
                            zoomPanBehavior: _irZoomPanBehavior,
                            primaryXAxis: NumericAxis(
                              title: AxisTitle(text: 'Time (Index)'),
                              autoScrollingDelta: 1500,
                              autoScrollingMode: AutoScrollingMode.end,
                            ),
                            primaryYAxis: NumericAxis(
                              minimum: _irYAxisMin,
                              maximum: _irYAxisMax,
                            ),
                            series: <CartesianSeries>[
                              FastLineSeries<PlotData, int>(
                                name: 'IR Channel',
                                dataSource: irChannelData,
                                xValueMapper: (PlotData data, _) => data.time,
                                yValueMapper: (PlotData data, _) => data.value,
                                animationDuration: 0,
                                emptyPointSettings: EmptyPointSettings(
                                  mode: EmptyPointMode.average,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Green Channel Chart - Collapsible
                    ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Green Channel',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                          // Text(
                          //   'Red Channel',
                          //   style: TextStyle(
                          //     fontSize: 18,
                          //     color: Colors.red,
                          //     fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                          IconButton(
                            icon: const Icon(Icons.zoom_out),
                            color: Colors.green,
                            onPressed: () {
                              setState(() {
                                // _redYAxisMin = redChannelData.isEmpty
                                //     ? 0
                                //     : redChannelData.map((data) => data.value).reduce(math.min);
                                // _redYAxisMax = redChannelData.isEmpty
                                //     ? 1
                                //     : redChannelData.map((data) => data.value).reduce(math.max);
                                // _zoomPanBehavior.reset();

                                _greenYAxisMin = greenChannelData.isEmpty
                                    ? 0
                                    : greenChannelData
                                    .map((data) => data.value)
                                    .reduce(math.min);
                                _greenYAxisMax = greenChannelData.isEmpty
                                    ? 1
                                    : greenChannelData
                                    .map((data) => data.value)
                                    .reduce(math.max);
                                _greenZoomPanBehavior.reset();
                              });
                            },
                          ),
                        ],
                      ),
                      children: [
                        SizedBox(
                          height: 300, // Adjust height as needed
                          child: SfCartesianChart(
                            // zoomPanBehavior: _zoomPanBehavior,
                            zoomPanBehavior: _greenZoomPanBehavior,
                            primaryXAxis: NumericAxis(
                              title: AxisTitle(text: 'Time (Index)'),
                              autoScrollingDelta: 1500,
                              autoScrollingMode: AutoScrollingMode.end,
                            ),
                            primaryYAxis: NumericAxis(
                              minimum: _greenYAxisMin,
                              maximum: _greenYAxisMax,
                            ),
                            series: <CartesianSeries>[
                              FastLineSeries<PlotData, int>(
                                name: 'Green Channel',
                                dataSource: greenChannelData,
                                xValueMapper: (PlotData data, _) => data.time,
                                yValueMapper: (PlotData data, _) => data.value,
                                animationDuration: 0,
                                emptyPointSettings: EmptyPointSettings(
                                  mode: EmptyPointMode.average,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // SingleChildScrollView(
              //   physics: AlwaysScrollableScrollPhysics(),
              //   child: Column(
              //     children: [
              //       Container(
              //         height:500,
              //         child: SfCartesianChart(
              //           title: ChartTitle(
              //             text: 'Red Channel', // Add your desired title here
              //             alignment: ChartAlignment.center, // Align the title (optional)
              //             textStyle: TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //           zoomPanBehavior: _zoomPanBehavior,
              //           primaryXAxis: NumericAxis(
              //             title: AxisTitle(text: 'Time (Index)'),
              //             autoScrollingDelta: 1500,
              //             autoScrollingMode: AutoScrollingMode.end,
              //           ),
              //           primaryYAxis: NumericAxis(
              //             minimum: _yAxisMin,
              //             maximum: _yAxisMax,
              //           ),
              //           series: <CartesianSeries>[
              //             FastLineSeries<PlotData, int>(
              //                 name: 'Red Channel',
              //                 dataSource: redChannelData,
              //                 xValueMapper: (PlotData data, _) => data.time,
              //                 yValueMapper: (PlotData data, _) => data.value,
              //                 animationDuration: 0,
              //                 emptyPointSettings: EmptyPointSettings(
              //                   mode: EmptyPointMode.average,
              //                 )),
              //           ],
              //         ),
              //       ),
              //       Container(
              //         height: 500,
              //         child: SfCartesianChart(
              //           title: ChartTitle(
              //             text: 'IR Channel', // Add your desired title here
              //             alignment: ChartAlignment.center, // Align the title (optional)
              //             textStyle: TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //           zoomPanBehavior: _zoomPanBehavior,
              //
              //           primaryXAxis: NumericAxis(
              //             title: AxisTitle(text: 'Time (Index)'),
              //             autoScrollingDelta: 1500,
              //             autoScrollingMode: AutoScrollingMode.end,
              //           ),
              //           primaryYAxis: NumericAxis(
              //             minimum: _yAxisMin,
              //             maximum: _yAxisMax,
              //           ),
              //           series: <CartesianSeries>[
              //             FastLineSeries<PlotData, int>(
              //                 name: 'IR Channel',
              //                 dataSource: irChannelData,
              //                 xValueMapper: (PlotData data, _) => data.time,
              //                 yValueMapper: (PlotData data, _) => data.value,
              //                 animationDuration: 0,
              //                 emptyPointSettings: EmptyPointSettings(
              //                   mode: EmptyPointMode.average,
              //                 )),
              //           ],
              //         ),
              //       ),
              //       SizedBox(height: 100,),
              //       Container(
              //         height: 500,
              //         child: SfCartesianChart(
              //           title: ChartTitle(
              //             text: 'Green Channel', // Add your desired title here
              //             alignment: ChartAlignment.center, // Align the title (optional)
              //             textStyle: TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //           zoomPanBehavior: _zoomPanBehavior,
              //           primaryXAxis: NumericAxis(
              //             title: AxisTitle(text: 'Time (Index)'),
              //             autoScrollingDelta: 1500,
              //             autoScrollingMode: AutoScrollingMode.end,
              //           ),
              //           primaryYAxis: NumericAxis(
              //             minimum: _yAxisMin,
              //             maximum: _yAxisMax,
              //           ),
              //           series: <CartesianSeries>[
              //             FastLineSeries<PlotData, int>(
              //                 name: 'Green Channel',
              //                 dataSource: greenChannelData,
              //                 xValueMapper: (PlotData data, _) => data.time,
              //                 yValueMapper: (PlotData data, _) => data.value,
              //                 animationDuration: 0,
              //                 emptyPointSettings: EmptyPointSettings(
              //                   mode: EmptyPointMode.average,
              //                 )),
              //           ],
              //         ),
              //       ),
              //
              //     ],
              //   ),
              // ),
            ),
            SizedBox(
              height: 100,
              child: ListView(
                children: _buildServiceTiles(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

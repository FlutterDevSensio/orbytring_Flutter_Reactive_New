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

  PlotScreenPPG({Key? key, required this.device, required this.services})
      : super(key: key);

  @override
  _PlotScreenPPGState createState() => _PlotScreenPPGState();
}

class _PlotScreenPPGState extends State<PlotScreenPPG> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final TextEditingController _commandController = TextEditingController();
  QualifiedCharacteristic? _notificationCharacteristic;
  Map<Uuid, bool> _notificationStates = {};
  int selectedValue = 100;

  List<PlotData> redChannelData = [];
  List<PlotData> irChannelData = [];
  List<PlotData> greenChannelData = [];
  int dataPointIndex = 0;

  double _yAxisMin = 0;
  double _yAxisMax = 1;

  ZoomPanBehavior _zoomPanBehavior = ZoomPanBehavior(
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

      _updateYAxisRange(finalData.toDouble());
    }
  }

  void _updateYAxisRange(double newValue) {
    setState(() {
      _yAxisMin = greenChannelData.isEmpty
          ? 0
          : greenChannelData.map((data) => data.value).reduce(math.min);
      _yAxisMax = greenChannelData.isEmpty
          ? 1
          : greenChannelData.map((data) => data.value).reduce(math.max);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomPanBehavior.reset();
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
      await _ble
          .writeCharacteristicWithoutResponse(characteristic, value: [0x00]);
      _ble.subscribeToCharacteristic(characteristic).listen(null).cancel();
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
                      icon: Icon(Icons.send),
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
            return SizedBox.shrink();
          }).toList(),
        );
      }
      return SizedBox.shrink();
    }).toList();
  }

  void _showCommandDialog(QualifiedCharacteristic characteristic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Command'),
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
            SizedBox(height: 16),
            TextField(
              controller: _commandController,
              decoration: InputDecoration(hintText: 'Command will be sent'),
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
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              String command = 'STARTPPG:$selectedValue';
              _sendCommand(characteristic, command);
              _commandController.clear();
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Real-time Green-Channel Data Plot"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: _zoomOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: SfCartesianChart(
                zoomPanBehavior: _zoomPanBehavior,
                primaryXAxis: NumericAxis(
                  title: AxisTitle(text: 'Time (Index)'),
                  autoScrollingDelta: 1500,
                  autoScrollingMode: AutoScrollingMode.end,
                ),
                primaryYAxis: NumericAxis(
                  minimum: _yAxisMin,
                  maximum: _yAxisMax,
                ),
                series: <ChartSeries>[
                  LineSeries<PlotData, int>(
                    name: 'Green Channel',
                    dataSource: greenChannelData,
                    xValueMapper: (PlotData data, _) => data.time,
                    yValueMapper: (PlotData data, _) => data.value,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView(
              children: _buildServiceTiles(),
            ),
          ),
        ],
      ),
    );
  }
}

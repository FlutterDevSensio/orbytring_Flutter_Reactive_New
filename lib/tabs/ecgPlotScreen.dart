import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;

// Data model for chart data
class PlotData {
  final int time; // Time or index of the data point
  final double value; // Data value received from notification

  PlotData(this.time, this.value);
}

int _dataPointsPerSecond = 0;

class PlotScreenECG extends StatefulWidget {
  final DiscoveredDevice device; // Bluetooth device parameter
  final List<DiscoveredService> services; // Services for the Bluetooth device

  PlotScreenECG({Key? key, required this.device, required this.services}) : super(key: key);

  @override
  _PlotScreenECGState createState() => _PlotScreenECGState();
}

class _PlotScreenECGState extends State<PlotScreenECG> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final TextEditingController _commandController = TextEditingController();
  QualifiedCharacteristic? _notificationCharacteristic;
  Map<Uuid, bool> _notificationStates = {};

  List<PlotData> channelData = [];
  int dataPointIndex = 0;
  int selectedValue = 100;

  double _yAxisMin = 0;
  double _yAxisMax = 1000; // Initial Y-axis range

  ZoomPanBehavior _zoomPanBehavior = ZoomPanBehavior(
    enablePinching: true,
    enablePanning: true,
    enableDoubleTapZooming: true,
  );

  @override
  void initState() {
    super.initState();
    _connectToDevice(); // Connect to the Bluetooth device
    _dataPointsPerSecond = 0;
  }

  Future<void> _connectToDevice() async {
    try {
      _ble.connectToDevice(id: widget.device.id).listen((connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _discoverServices();
        }
      }, onError: (e) {
        print("Error connecting to device: $e");
      });
    } catch (e) {
      print("Error connecting to device: $e");
    }
  }

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

  Future<void> _enableNotifications(QualifiedCharacteristic characteristic) async {
    try {
      _notificationCharacteristic = characteristic;
      _ble.subscribeToCharacteristic(characteristic).listen((value) {
        print('Notification received: $value');
        groupBytesIntoSamples(value); // Process incoming data
      }, onError: (e) {
        print('Error receiving notifications: $e');
      });

      setState(() {
        _notificationStates[characteristic.characteristicId] = true;
      });
    } catch (e) {
      print('Error enabling notifications: $e');
    }
  }

  void groupBytesIntoSamples(List<int> value) {
    int sampleCount = value.length ~/ 2;
    for (int i = 0; i < sampleCount; i++) {
      int offset = i * 2;
      int sample1 = value[offset];
      int sample2 = value[offset + 1];
      int ecgData = (sample1 << 8) | sample2;
      channelData.add(PlotData(dataPointIndex++, ecgData.toDouble()));
      _updateYAxisRange(ecgData.toDouble());
      _dataPointsPerSecond++;
    }
  }

  // void _updateYAxisRange(double newValue) {
  //   setState(() {
  //
  //     final List<double> last1500Data = channelData
  //         .map((data) => data.value as double)
  //         .toList()
  //         .skip(
  //         channelData.length > 500 ? channelData.length - 500 : 0)
  //         .toList();
  //
  //     if (channelData.isNotEmpty) {
  //       _yAxisMin = last1500Data.isEmpty ? 0 : last1500Data.reduce(math.min);
  //       print(_yAxisMin);
  //       _yAxisMax = last1500Data.isEmpty ? 1 : last1500Data.reduce(math.max);
  //       print(_yAxisMax);
  //       // _yAxisMin = channelData.map((data) => data.value).reduce(math.min);
  //       // _yAxisMax = channelData.map((data) => data.value).reduce(math.max);
  //     } else {
  //       _yAxisMin = 0;
  //       _yAxisMax = 1000; // Default range
  //     }
  //   });
  // }

  void _updateYAxisRange(double newValue) {
    setState(() {

      final List<double> last1500Data = channelData
          .map((data) => data.value as double)
          .toList()
          .skip(
          channelData.length > 500 ? channelData.length - 500 : 0)
          .toList();

      if (channelData.isNotEmpty) {

        // _yAxisMin = channelData.map((data) => data.value).reduce(math.min);
        // _yAxisMin = last1500Data.isEmpty ? 0 : (last1500Data.reduce(math.min));
        // print(_yAxisMin);
        _yAxisMin = last1500Data.isEmpty
            ? 0
            : (last1500Data.reduce(math.min) > 3000
            ? last1500Data.reduce(math.min) - 3000
            : 0);
        _yAxisMax = last1500Data.isEmpty ? 1 : (last1500Data.reduce(math.max)+3000);

        // _yAxisMax = last1500Data.isEmpty ? 1 : (last1500Data.reduce(math.max)+last1500Data.reduce(math.max)/3);
        // print(_yAxisMax);
        // _yAxisMax = channelData.map((data) => data.value).reduce(math.max);
      } else {
        _yAxisMin = 0;
        _yAxisMax = 1000; // Default range
      }
    });
  }

  List<Widget> _buildServiceTiles() {
    return widget.services.map((service) {
      if (service.serviceId.toString().toUpperCase() == '4E771A15-2665-CF92-8569-8C642A4AB357') {
        return Column(
          children: service.characteristics.map((characteristic) {
            final qualifiedCharacteristic = QualifiedCharacteristic(
              deviceId: widget.device.id,
              serviceId: service.serviceId,
              characteristicId: characteristic.characteristicId,
            );


            // ExpansionTile(
            // title: Text('Service: ${service.serviceId.toString().toUpperCase()}'),
            // children: service.characteristics.map((characteristic) {
            //   final qualifiedCharacteristic = QualifiedCharacteristic(
            //     deviceId: widget.device.id,
            //     serviceId: service.serviceId,
            //     characteristicId: characteristic.characteristicId,
            //   );
            if (characteristic.characteristicId.toString().toUpperCase() == '48837CB0-B733-7C24-31B7-222222222222') {
              return
                // ListTile(
                // title: Text('Characteristic: ${characteristic.characteristicId.toString().toUpperCase()}'),
                // trailing:
                //
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                          (_notificationStates[characteristic.characteristicId] ?? false)
                              ? Icons.notifications
                              : Icons.notifications_off,
                        ),
                        onPressed: () async {
                          if (_notificationStates[characteristic.characteristicId] == true) {
                            await _disableNotifications(qualifiedCharacteristic);
                          } else {
                            await _enableNotifications(qualifiedCharacteristic);
                          }
                        },
                      ),
                  ],
                  // ),
                );
            }
            return Container();
          }).toList(),
        );
      }
      return SizedBox.shrink();
    }).toList();
  }

  Future<void> _disableNotifications(QualifiedCharacteristic characteristic) async {
    try {
      // await _ble.writeCharacteristicWithoutResponse(characteristic, value: [0x00]);
      _sendCommand(characteristic, "STOPECG");
      setState(() {
        print("We are setting it off");
        _notificationStates[characteristic.characteristicId] = false;
      });
      print('Notifications disabled for: ${characteristic.characteristicId}');
    } catch (e) {
      print('Error disabling notifications: $e');
    }
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
                  _commandController.text = 'STARTECG:$selectedValue';
                });
              },
              items: [60, 100, 200, 500, 1000].map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
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
              String command = 'STARTECG:$selectedValue';
              _sendCommand(characteristic, command);
              _commandController.clear();
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCommand(QualifiedCharacteristic characteristic, String command) async {
    final bytes = command.codeUnits;
    try {
      await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);
      print("Command sent: $command");
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  void _zoomOut() {
    setState(() {
      _zoomPanBehavior.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ECG Plot"),
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
            child: SfCartesianChart(
              zoomPanBehavior: _zoomPanBehavior,
              primaryXAxis: NumericAxis(
                title: AxisTitle(text: 'Time (Index)'),
                // autoScrollingDelta: selectedValue * 500,
                autoScrollingDelta: 1500,
                // autoScrollingDelta: channelData.length,
                autoScrollingMode: AutoScrollingMode.end,
              ),
              primaryYAxis: NumericAxis(
                minimum: _yAxisMin,
                maximum: _yAxisMax,
              ),
              // series: <ChartSeries>[
              //   LineSeries<PlotData, int>(
              //     name: 'ECG Channel',
              //     dataSource: channelData,
              //     xValueMapper: (PlotData data, _) => data.time,
              //     yValueMapper: (PlotData data, _) => data.value,
              //   ),
              // ],
              series: <CartesianSeries>[
                FastLineSeries<PlotData, int>(
                  name: 'ECG Channel',
                  dataSource: channelData,
                  xValueMapper: (PlotData data, _) => data.time,
                  yValueMapper: (PlotData data, _) => data.value,
                  animationDuration: 0,
                ),

              ],
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
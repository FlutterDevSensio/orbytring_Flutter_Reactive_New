
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:orbytring_new/tabs/ecgPlotScreen.dart';
import 'package:orbytring_new/tabs/ppgPlotScreen.dart';
import 'package:orbytring_new/DeviceMannualInputScreen.dart';

class DeviceScreen extends StatefulWidget {
  final DiscoveredDevice device;

  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> with TickerProviderStateMixin {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final TextEditingController _commandController = TextEditingController();
  List<DiscoveredService> _services = [];
  QualifiedCharacteristic? _notificationCharacteristic;
  Map<Uuid, bool> _notificationStates = {};
  List<int> _dataBuffer = [];

  String? lastCommand;
  String? heartRate;
  String? bloodOxygen;
  String? temperature;

  // Timer variables
  Timer? _timer;
  int _remainingTime = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _discoverServices();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> _discoverServices() async {
    try {
      final mtu = await _ble.requestMtu(deviceId: widget.device.id, mtu: 512);
      print("MTU negotiated: $mtu");
      final services = await _ble.discoverServices(widget.device.id);
      setState(() {
        _services = services;
      });
    } catch (e) {
      print("Error discovering services: $e");
    }
  }

  Future<void> _sendCommand(QualifiedCharacteristic characteristic, String command) async {
    print("Sending command: $command");
    lastCommand = command;
    final bytes = command.codeUnits;
    try {
      print(characteristic.characteristicId.data);
      await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);
    } catch (e) {
      print("Error sending command: $e");
      await _ble.writeCharacteristicWithoutResponse(characteristic, value: bytes);
    }
  }

  Future<void> _enableNotifications(QualifiedCharacteristic characteristic) async {
    try {
      _notificationCharacteristic = characteristic;
      _ble.subscribeToCharacteristic(characteristic).listen((value) {
        _updateVitals(value);
        print('Notification received: $value');
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

  void _updateVitals(List<int> value) {
    if (lastCommand == 'hrm' && value.isNotEmpty) {
      double hr = calculateAverage(value);
      setState(() {
        heartRate = hr == 0.00 ? 'Heart Rate: --' : 'Heart Rate: ${hr.toStringAsFixed(2)}';
      });
    } else if (lastCommand == 'spo2' && value.isNotEmpty) {
      double spo2 = calculateAverage(value);
      setState(() {
        bloodOxygen = spo2 == 0.00 ? 'Blood Oxygen: --' : 'Blood Oxygen: ${spo2.toStringAsFixed(2)}';
      });
    } else if (lastCommand == 'temp' && value.isNotEmpty) {
      double temp = ((calculateAverage(value) + 200.0) / 10);
      setState(() {
        temperature = temp == 0.00 ? 'Temperature: --' : 'Temperature: ${temp.toStringAsFixed(2)}';
      });
    } else {
      print('Received unexpected data: $value');
    }
  }

  double calculateAverage(List<int> values) {
    List<int> nonZeroValues = values.where((value) => value != 0).toList();
    if (nonZeroValues.isEmpty) {
      return 0.0;
    }
    double sum = nonZeroValues.reduce((a, b) => a + b).toDouble();
    return sum / nonZeroValues.length;
  }

  Future<void> _refreshVitals(QualifiedCharacteristic characteristic) async {
    await _sendCommand(characteristic, "hrm");
    await _sendCommand(characteristic, "spo2");
    await _sendCommand(characteristic, "temp");
  }

  Future<void> _sendResetCommand(QualifiedCharacteristic characteristic) async {
    setState(() {
      _notificationStates[characteristic.characteristicId] = false;
    });
    _startTimer(characteristic);
    await _sendCommand(characteristic, "RST");
  }

  void _startTimer(QualifiedCharacteristic characteristic) {
    setState(() {
      _remainingTime = 31;
    });

    _timer?.cancel();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), () async {
          await _enableNotifications(characteristic);
          await Future.delayed(const Duration(milliseconds: 500));
          await _refreshVitals(characteristic);
        });
      }
    });
  }

  List<Widget> _buildServiceTiles() {
    return _services.map((service) {
      if (service.serviceId.toString().toUpperCase() == 'A0262760-08C2-11E1-9073-0E8AC72E1234') {
        return ExpansionTile(
          title: Text(' '),
          children: service.characteristics.map((characteristic) {
            final qualifiedCharacteristic = QualifiedCharacteristic(
              serviceId: service.serviceId,
              characteristicId: characteristic.characteristicId,
              deviceId: widget.device.id,
            );
            if (characteristic.characteristicId.toString().toUpperCase() ==
                'A0262760-08C2-11E1-9073-0E8AC72E0001') {
              return _buildControlPanel(qualifiedCharacteristic);
            }
            return ListTile(
              title: Text('Characteristic: ${characteristic.characteristicId.toString().toUpperCase()}'),
            );
          }).toList(),
        );
      }
      return SizedBox.shrink();
    }).toList();
  }

  Widget _buildControlPanel(QualifiedCharacteristic characteristic) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blueGrey, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vitals Control Panel",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
          ),
          SizedBox(height: 10),
          _buildVitalInfo(heartRate ?? "Heart Rate: --", Icons.favorite, Colors.red),
          _buildVitalInfo(bloodOxygen ?? "Blood Oxygen: --", Icons.opacity, Colors.blue),
          _buildVitalInfo(temperature ?? "Temperature: --", Icons.thermostat, Colors.orange),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(Icons.refresh, () => _refreshVitals(characteristic), "Refresh"),
              _buildNotificationButton(characteristic),
              _buildIconButton(Icons.reset_tv, () => _sendResetCommand(characteristic), "Reset"),
            ],
          ),
          if (_remainingTime > 0) ...[
            SizedBox(height: 20),
            Text(
              "Fetch Vitals in $_remainingTime seconds",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
            ),
          ],
          if (_remainingTime == 0) ...[
            Text(
              "You are all set to fetch the vitals",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildVitalInfo(String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        SizedBox(width: 8),
        Text(
          "$value",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      color: Colors.blueGrey,
      iconSize: 30,
    );
  }

  Widget _buildNotificationButton(QualifiedCharacteristic characteristic) {
    return IconButton(
      icon: Icon(
        (_notificationStates[characteristic.characteristicId] ?? false)
            ? Icons.notifications
            : Icons.notifications_off,
        color: Colors.blueGrey,
      ),
      tooltip: "Notifications",
      onPressed: () async {
        if (_notificationStates[characteristic.characteristicId] == true) {
          setState(() => _notificationStates[characteristic.characteristicId] = false);
        } else {
          await _enableNotifications(characteristic);
        }
      },
      iconSize: 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Vitals'),
            Tab(text: 'PPG Plot'),
            Tab(text: 'ECG Plot'),
            Tab(text: 'All Services'),
          ],
        ),
        actions: [
          StreamBuilder<DeviceConnectionState>(
            stream: _ble.connectedDeviceStream
                .where((event) => event.deviceId == widget.device.id)
                .map((event) => event.connectionState),
            initialData: DeviceConnectionState.connected,
            builder: (context, snapshot) {
              if (snapshot.data == DeviceConnectionState.connected) {
                return ElevatedButton(
                  onPressed: () => {},
                      // _ble.disconnectDevice(id: widget.device.id),
                  child: Text('DISCONNECT'),
                );
              } else {
                return ElevatedButton(
                  onPressed: () => _ble.connectToDevice(id: widget.device.id),
                  child: Text('CONNECT'),
                );
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _services.isEmpty
              ? Center(child: Text("Services are Empty"))
              : ListView(children: _buildServiceTiles()),
          _services.isEmpty
              ? Center(child: Text("Services are Empty"))
              : PlotScreenPPG(
            services: _services,
            device: widget.device,
          ),
          _services.isEmpty
              ? Center(child: Text("Services are Empty"))
              : PlotScreenECG(
            services: _services,
            device: widget.device,
          ),
          // _services.isEmpty
          //     ? Center(child: Text("Services are Empty"))
          //     : PlotScreenECG(
          //   services: _services,
          //   device: widget.device,
          // ),
          _services.isEmpty
              ? Center(child: Text("Services are Empty"))
              : MannualInputScreen(device: widget.device),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}

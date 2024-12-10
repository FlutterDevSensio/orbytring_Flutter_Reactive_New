import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class MannualInputScreen extends StatefulWidget {
  final DiscoveredDevice device;

  const MannualInputScreen({Key? key, required this.device}) : super(key: key);

  @override
  _MannualInputScreenState createState() => _MannualInputScreenState();
}

class _MannualInputScreenState extends State<MannualInputScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final TextEditingController _commandController = TextEditingController();
  List<DiscoveredService> _services = [];
  QualifiedCharacteristic? _notificationCharacteristic;
  Map<Uuid, bool> _notificationStates = {};

  List<String> notifications = []; // Store incoming notifications

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }
  //
  // Future<void> _discoverServices() async {
  //   try {
  //     final services = await _ble.discoverServices(widget.device.id);
  //     setState(() {
  //       _services = services;
  //     });
  //   } catch (e) {
  //     print("Error discovering services: $e");
  //   }
  // }
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
    final bytes = command.codeUnits; // Convert string command to bytes
    try {
      await _ble.writeCharacteristicWithResponse(characteristic, value: bytes);
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  Future<void> _enableNotifications(QualifiedCharacteristic characteristic) async {
    try {
      _notificationCharacteristic = characteristic;
      _ble.subscribeToCharacteristic(characteristic).listen((data) {
        print('Notification received: $data');
        setState(() {
          notifications.add('Notification: ${data}');
        });
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

  Future<void> _disableNotifications(QualifiedCharacteristic characteristic) async {
    try {
      setState(() {
        _notificationStates[characteristic.characteristicId] = false;
      });
    } catch (e) {
      print('Error disabling notifications: $e');
    }
  }

  List<Widget> _buildServiceTiles() {
    return _services.map((service) {
      return ExpansionTile(
        title: Text('Service: ${service.serviceId.toString().toUpperCase()}'),
        children: service.characteristics.map((characteristic) {
          final qualifiedCharacteristic = QualifiedCharacteristic(
            serviceId: service.serviceId,
            characteristicId: characteristic.characteristicId,
            deviceId: widget.device.id,
          );
          return ListTile(
            title: Text('Characteristic: ${characteristic.characteristicId.toString().toUpperCase()}'),
            // subtitle: Text('Properties: ${characteristic.properties}'),
            subtitle: Text('Properties: ${characteristic}'),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Send Command Button
                if (characteristic.isWritableWithResponse)
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      _showCommandDialog(qualifiedCharacteristic);
                    },
                  ),

                // Notification Toggle Button
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
            ),
          );
        }).toList(),
      );
    }).toList();
  }

  void _showCommandDialog(QualifiedCharacteristic characteristic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Command'),
        content: TextField(
          controller: _commandController,
          decoration: InputDecoration(hintText: 'Enter command to send'),
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
              _sendCommand(characteristic, _commandController.text);
              _commandController.clear();
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  // Close button action
  void _closeNotificationWindow() {
    Navigator.pop(context); // Close the current screen
  }

  // Clear button action
  void _clearNotifications() {
    setState(() {
      notifications.clear(); // Clear all notifications
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Upper half for List of Bluetooth Services
          Expanded(
            flex: 1,
            child: _services.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView(
              children: _buildServiceTiles(),
            ),
          ),
          // Bottom half for Notifications (Scrollable)
          Expanded(
            flex: 1,
            child: NotificationWindow(
              notifications: notifications,
              onClose: _closeNotificationWindow,
              onClear: _clearNotifications,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }
}

class NotificationWindow extends StatelessWidget {
  final List<String> notifications;
  final VoidCallback onClose;
  final VoidCallback onClear;

  const NotificationWindow({
    Key? key,
    required this.notifications,
    required this.onClose,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          // Row with Close and Clear buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: onClose, // Call onClose callback
              ),
              // Clear button
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: onClear, // Call onClear callback
              ),
            ],
          ),
          // Notification List
          Expanded(
            child: ListView(
              children: [
                for (var notification in notifications)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      notification,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
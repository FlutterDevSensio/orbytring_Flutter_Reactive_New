import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';

class BleController extends GetxController {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final _scanResults = <DiscoveredDevice>[].obs;

  Stream<List<DiscoveredDevice>> get scanResultsStream => _ble.scanForDevices(
        withServices: [],
        scanMode: ScanMode.lowLatency,
      ).map((device) {
        if (!_scanResults.any((d) => d.id == device.id)) {
          _scanResults.add(device);
        }
        return _scanResults.toList();
      });

  void scanDevices() {
    _ble.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen(
        (device) {
      if (!_scanResults.any((d) => d.id == device.id)) {
        _scanResults.add(device);
        update();
      }
    });
  }
}

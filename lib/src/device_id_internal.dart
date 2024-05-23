import '../countly_flutter.dart';
import 'device_id.dart';

class DeviceIDInternal implements DeviceID {
  @override
  Future<void> changeDeviceIDWithMerge(String newDeviceID) {
    throw UnimplementedError();
  }

  @override
  Future<void> changeDeviceIDWithoutMerge(String newDeviceID) {
    throw UnimplementedError();
  }

  @override
  Future<String> getCurrentDeviceID() {
    throw UnimplementedError();
  }

  @override
  Future<DeviceIdType> getDeviceIDType() {
    throw UnimplementedError();
  }

  @override
  Future<void> setID() {
    throw UnimplementedError();
  }
}

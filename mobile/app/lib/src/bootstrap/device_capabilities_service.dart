import 'dart:io';

import 'package:flutter/services.dart';

class DeviceCapabilities {
  const DeviceCapabilities({
    this.androidSdkInt,
    this.isLowRamDevice = false,
  });

  final int? androidSdkInt;
  final bool isLowRamDevice;
}

abstract class DeviceCapabilitiesService {
  Future<DeviceCapabilities> readCapabilities();
}

class MethodChannelDeviceCapabilitiesService
    implements DeviceCapabilitiesService {
  static const MethodChannel _channel = MethodChannel(
    'com.zokorp.ummah/device_capabilities',
  );

  @override
  Future<DeviceCapabilities> readCapabilities() async {
    if (!Platform.isAndroid) {
      return const DeviceCapabilities();
    }
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMapMethod<Object?, Object?>(
        'getDeviceCapabilities',
      );
      return DeviceCapabilities(
        androidSdkInt: raw?['androidSdkInt'] as int?,
        isLowRamDevice: raw?['isLowRamDevice'] as bool? ?? false,
      );
    } on PlatformException {
      return const DeviceCapabilities();
    }
  }
}

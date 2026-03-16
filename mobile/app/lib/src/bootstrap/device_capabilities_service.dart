import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceCapabilities {
  const DeviceCapabilities({
    required this.androidSdkInt,
    required this.isLowRamDevice,
  });

  final int? androidSdkInt;
  final bool isLowRamDevice;

  bool get shouldDefaultLeanMode {
    return isLowRamDevice ||
        (androidSdkInt != null && androidSdkInt! >= 24 && androidSdkInt! <= 26);
  }
}

class DeviceCapabilitiesService {
  DeviceCapabilitiesService({
    MethodChannel? channel,
  }) : _channel = channel ??
            const MethodChannel('com.zokorp.ummah/device_capabilities');

  final MethodChannel _channel;

  Future<DeviceCapabilities> load() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const DeviceCapabilities(
        androidSdkInt: null,
        isLowRamDevice: false,
      );
    }

    try {
      final Map<Object?, Object?>? raw = await _channel
          .invokeMapMethod<Object?, Object?>('getDeviceCapabilities');
      final Object? rawAndroidSdkInt = raw?['androidSdkInt'];
      return DeviceCapabilities(
        androidSdkInt: rawAndroidSdkInt is int
            ? rawAndroidSdkInt
            : int.tryParse('${rawAndroidSdkInt ?? ''}'),
        isLowRamDevice: raw?['isLowRamDevice'] == true,
      );
    } on PlatformException {
      return const DeviceCapabilities(
        androidSdkInt: null,
        isLowRamDevice: false,
      );
    } on MissingPluginException {
      return const DeviceCapabilities(
        androidSdkInt: null,
        isLowRamDevice: false,
      );
    }
  }

  Future<UiPerformanceMode> resolve({
    UiPerformanceMode? override,
  }) async {
    if (override != null) {
      return override;
    }

    final DeviceCapabilities capabilities = await load();
    return capabilities.shouldDefaultLeanMode
        ? UiPerformanceMode.lean
        : UiPerformanceMode.standard;
  }
}

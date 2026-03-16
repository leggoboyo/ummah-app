package com.zokorp.ummah

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val DEVICE_CAPABILITIES_CHANNEL = "com.zokorp.ummah/device_capabilities"
        private const val METHOD_GET_DEVICE_CAPABILITIES = "getDeviceCapabilities"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CAPABILITIES_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_DEVICE_CAPABILITIES -> {
                    val activityManager =
                        getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    result.success(
                        mapOf(
                            "androidSdkInt" to android.os.Build.VERSION.SDK_INT,
                            "isLowRamDevice" to activityManager.isLowRamDevice,
                        ),
                    )
                }

                else -> result.notImplemented()
            }
        }
    }
}

package com.zokorp.ummah

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.zokorp.ummah/device_capabilities",
        ).setMethodCallHandler { call, result ->
            if (call.method != "getDeviceCapabilities") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val activityManager =
                getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            result.success(
                mapOf(
                    "androidSdkInt" to Build.VERSION.SDK_INT,
                    "isLowRamDevice" to activityManager.isLowRamDevice,
                ),
            )
        }
    }
}

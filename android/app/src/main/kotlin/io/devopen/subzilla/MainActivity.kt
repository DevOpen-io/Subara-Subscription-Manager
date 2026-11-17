package io.devopen.subzilla

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity is required by local_auth (app lock).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Opens the "Alarms & reminders" screen for this app in both
        // directions; the notifications plugin only opens it to grant.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.devopen.subzilla/exact_alarms")
            .setMethodCallHandler { call, result ->
                // Before Android 12 exact alarms need no permission and there
                // is no screen to open.
                val hasScreen = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                if (call.method == "hasSettings") return@setMethodCallHandler result.success(hasScreen)
                if (call.method != "openSettings") return@setMethodCallHandler result.notImplemented()
                if (!hasScreen) return@setMethodCallHandler result.success(false)
                try {
                    startActivity(
                        Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName"))
                    )
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
    }
}

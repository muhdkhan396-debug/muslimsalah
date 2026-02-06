package com.masjidsilentmode

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "com.masjidsilentmode/silent"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "checkPolicyAccess" -> {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            result.success(notificationManager.isNotificationPolicyAccessGranted)
          }
          "openPolicySettings" -> {
            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success(null)
          }
          "getRingerMode" -> {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            result.success(audioManager.ringerMode)
          }
          "setRingerMode" -> {
            val mode = call.argument<Int>("mode") ?: AudioManager.RINGER_MODE_NORMAL
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.ringerMode = mode
            result.success(null)
          }
          "setDnd" -> {
            val enabled = call.argument<Boolean>("enabled") ?: false
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
              if (notificationManager.isNotificationPolicyAccessGranted) {
                notificationManager.setInterruptionFilter(
                  if (enabled) NotificationManager.INTERRUPTION_FILTER_NONE else NotificationManager.INTERRUPTION_FILTER_ALL
                )
              }
            }
            result.success(null)
          }
          else -> result.notImplemented()
        }
      }
  }
}

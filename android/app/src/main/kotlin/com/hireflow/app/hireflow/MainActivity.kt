package com.hireflow.app.hireflow

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val MOMO_CHANNEL = "com.hireflow.app/momo_launcher"
    private val NOTIF_CHANNEL = "com.hireflow.app/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MoMo Launcher Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MOMO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openMoMoApp" -> {
                    val amount = call.argument<String>("amount") ?: ""
                    val orderCode = call.argument<String>("orderCode") ?: ""
                    val phone = call.argument<String>("phone") ?: "0364663787"
                    val deeplink = call.argument<String>("deeplink") ?: ""

                    var launched = false

                    // 1. First attempt: Launch com.mservice.momotransfer (MoMo test app on emulator)
                    try {
                        val intent = Intent().apply {
                            component = ComponentName("com.mservice.momotransfer", "com.mservice.momotransfer.MainActivity")
                            putExtra("amount", amount)
                            putExtra("bookingCode", orderCode)
                            putExtra("autoOpenPayment", true)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        startActivity(intent)
                        launched = true
                    } catch (e: Exception) {
                        // 2. Second attempt: Launch via package manager
                        try {
                            val launchIntent = packageManager.getLaunchIntentForPackage("com.mservice.momotransfer")
                            if (launchIntent != null) {
                                launchIntent.putExtra("amount", amount)
                                launchIntent.putExtra("bookingCode", orderCode)
                                launchIntent.putExtra("autoOpenPayment", true)
                                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                                startActivity(launchIntent)
                                launched = true
                            }
                        } catch (_: Exception) {}
                    }

                    // 3. Fallback: URI deeplink
                    if (!launched && deeplink.isNotEmpty()) {
                        try {
                            val uriIntent = Intent(Intent.ACTION_VIEW, Uri.parse(deeplink)).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(uriIntent)
                            launched = true
                        } catch (_: Exception) {}
                    }

                    result.success(launched)
                }
                else -> result.notImplemented()
            }
        }

        // System Notifications Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showSystemNotification" -> {
                    val title = call.argument<String>("title") ?: "HireFlow: Cập nhật hồ sơ"
                    val message = call.argument<String>("message") ?: ""
                    try {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        val channelId = "hireflow_status_channel"
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val channel = NotificationChannel(
                                channelId,
                                "Thông báo ứng tuyển HireFlow",
                                NotificationManager.IMPORTANCE_HIGH
                            ).apply {
                                description = "Thông báo cập nhật trạng thái đơn ứng tuyển"
                                enableLights(true)
                                enableVibration(true)
                            }
                            notificationManager.createNotificationChannel(channel)
                        }

                        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        val pendingIntent = PendingIntent.getActivity(
                            this,
                            0,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        val notification = NotificationCompat.Builder(this, channelId)
                            .setSmallIcon(android.R.drawable.ic_dialog_info)
                            .setContentTitle(title)
                            .setContentText(message)
                            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                            .setPriority(NotificationCompat.PRIORITY_HIGH)
                            .setAutoCancel(true)
                            .setContentIntent(pendingIntent)
                            .build()

                        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIF_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

package com.example.frontend

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)

            // Canal principal — alta importancia con sonido
            val mainChannel = NotificationChannel(
                "inclass_main",
                "InClass Notificaciones",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificaciones de clases y asistencia"
                enableVibration(true)
                enableLights(true)
            }

            manager.createNotificationChannel(mainChannel)
        }
    }
}
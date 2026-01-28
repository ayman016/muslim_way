package com.example.muslim_way

import io.flutter.app.FlutterApplication
import androidx.work.Configuration
import androidx.work.WorkManager

class Application : FlutterApplication(), Configuration.Provider {
    
    override fun onCreate() {
        super.onCreate()
        
        // ✅ تهيئة WorkManager يدوياً
        try {
            WorkManager.initialize(
                this,
                workManagerConfiguration
            )
            android.util.Log.d("Application", "✅ WorkManager initialized successfully")
        } catch (e: Exception) {
            android.util.Log.e("Application", "❌ WorkManager initialization failed: ${e.message}")
        }
    }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
}
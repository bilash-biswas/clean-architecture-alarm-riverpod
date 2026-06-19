package com.antigravity.alarm.alarm

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyAlarmWindowFlags()
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        applyAlarmWindowFlags()
    }

    /**
     * Forces the screen to wake up and show above the lock screen.
     * Required for true full-screen alarm display when the screen is off.
     */
    private fun applyAlarmWindowFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            // Android 8.1+ — use activity-level APIs
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            // Android 8.0 and below — use window flags
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }
}

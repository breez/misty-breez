package com.breez.liquid.l_breez

import android.annotation.SuppressLint
import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.os.SystemClock
import androidx.core.content.ContextCompat
import breez_sdk_liquid_notification.Constants
import breez_sdk_liquid_notification.Message
import breez_sdk_liquid_notification.MessagingService
import com.breez.liquid.l_breez.BreezLogger.Companion.configureLogger
import com.google.android.gms.common.util.PlatformVersion.isAtLeastLollipop
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.tinylog.kotlin.Logger

@SuppressLint("MissingFirebaseInstanceTokenRefresh")
class BreezFcmService : MessagingService, FirebaseMessagingService() {
    companion object {
        private const val TAG = "BreezFcmService"
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        configureLogger(applicationContext)
        Logger.tag(TAG).debug { "FCM message received!" }

        if (remoteMessage.priority == RemoteMessage.PRIORITY_HIGH) {
            Logger.tag(TAG).debug { "onMessageReceived from: ${remoteMessage.from}" }
            Logger.tag(TAG).debug { "onMessageReceived data: ${remoteMessage.data}" }
            remoteMessage.asMessage()
                ?.also { message -> startServiceIfNeeded(applicationContext, message) }
        } else {
            Logger.tag(TAG).debug { "Ignoring FCM message" }
        }
    }

    private fun RemoteMessage.asMessage(): Message? {
        return data[Constants.MESSAGE_DATA_TYPE]?.let {
            Message(
                data[Constants.MESSAGE_DATA_TYPE], data[Constants.MESSAGE_DATA_PAYLOAD]
            )
        }
    }

    override fun startForegroundService(message: Message) {
        Logger.tag(TAG).debug { "Starting BreezForegroundService w/ message ${message.type}: ${message.payload}" }
        val intent = Intent(applicationContext, BreezForegroundService::class.java)
        intent.putExtra(Constants.EXTRA_REMOTE_MESSAGE, message)
        ContextCompat.startForegroundService(applicationContext, intent)
    }

    @SuppressLint("VisibleForTests")
    override fun isAppForeground(context: Context): Boolean {
        val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (keyguardManager.isKeyguardLocked) {
            return false // Screen is off or lock screen is showing
        }
        // Screen is on and unlocked, now check if the process is in the foreground
        if (!isAtLeastLollipop()) {
            // Before L the process has IMPORTANCE_FOREGROUND while it executes BroadcastReceivers.
            // As soon as the service is started the BroadcastReceiver should stop.
            // UNFORTUNATELY the system might not have had the time to downgrade the process
            // (this is happening consistently in JellyBean).
            // With SystemClock.sleep(10) we tell the system to give a little bit more of CPU
            // to the main thread (this code is executing on a secondary thread) allowing the
            // BroadcastReceiver to exit the onReceive() method and downgrade the process priority.
            SystemClock.sleep(10)
        }
        val pid = Process.myPid()
        val am = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = am.runningAppProcesses
        if (appProcesses != null) {
            for (process in appProcesses) {
                if (process.pid == pid) {
                    return process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
                }
            }
        }
        return false
    }
}
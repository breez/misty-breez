package com.breez.misty

import android.annotation.SuppressLint
import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Process
import androidx.core.content.ContextCompat
import breez_sdk_liquid_notification.Constants.EXTRA_REMOTE_MESSAGE
import breez_sdk_liquid_notification.Constants.MESSAGE_DATA_PAYLOAD
import breez_sdk_liquid_notification.Constants.MESSAGE_DATA_TYPE
import breez_sdk_liquid_notification.Message
import breez_sdk_liquid_notification.MessagingService
import breez_sdk_liquid_notification.ServiceLogger
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

@SuppressLint("MissingFirebaseInstanceTokenRefresh")
class BreezFcmService :
    FirebaseMessagingService(),
    MessagingService {
    companion object {
        private const val TAG = "BreezFcmService"
    }

    private val logger by lazy {
        val fileLogger = BreezFileLogger.getInstance(applicationContext)
        fileLogger.minLevel = BreezFileLogger.LogLevel.INFO
        ServiceLogger(fileLogger)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        logger.log(TAG, "FCM message received!", "INFO")

        if (remoteMessage.priority == RemoteMessage.PRIORITY_HIGH) {
            logger.log(TAG, "onMessageReceived from: ${remoteMessage.from}", "INFO")
            logger.log(TAG, "onMessageReceived data: ${remoteMessage.data}", "INFO")
            remoteMessage.toMessage()?.let { startServiceIfNeeded(applicationContext, it) }
        } else {
            logger.log(TAG, "Ignoring FCM message", "INFO")
        }
    }

    override fun startForegroundService(message: Message) {
        logger.log(TAG, "Starting BreezForegroundService w/ message ${message.type}: ${message.payload}", "INFO")
        Intent(applicationContext, BreezForegroundService::class.java)
            .putExtra(EXTRA_REMOTE_MESSAGE, message)
            .let { ContextCompat.startForegroundService(applicationContext, it) }
    }

    override fun isAppForeground(context: Context): Boolean {
        val keyguardManager = context.getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (keyguardManager.isKeyguardLocked) return false

        val am = context.getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val pid = Process.myPid()
        return am.runningAppProcesses?.any {
            it.pid == pid && it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        } ?: false
    }

    private fun RemoteMessage.toMessage(): Message? = data[MESSAGE_DATA_TYPE]?.let { Message(it, data[MESSAGE_DATA_PAYLOAD]) }
}

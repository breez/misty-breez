package com.breez.misty

import breez_sdk_liquid.ConnectRequest
import breez_sdk_liquid.LiquidNetwork
import breez_sdk_liquid.LogEntry
import breez_sdk_liquid.Logger
import breez_sdk_liquid.defaultConfig
import breez_sdk_liquid.setLogger
import breez_sdk_liquid_notification.ForegroundService
import breez_sdk_liquid_notification.NotificationHelper.Companion.registerNotificationChannels
import breez_sdk_liquid_notification.ServiceLogger
import com.breez.misty.utils.readSecuredValue
import io.flutter.util.PathUtils

class BreezForegroundService : ForegroundService() {
    override fun onCreate() {
        super.onCreate()
        val fileLogger = BreezFileLogger.getInstance(applicationContext)
        this.logger = ServiceLogger(fileLogger)
        // Set the SDK logger for background operations
        // The SDK logger is separate from the service logger used by the notification plugin
        try {
            setLogger(object : Logger {
                override fun log(l: LogEntry) {
                    // Forward SDK logs to our file logger
                    fileLogger.log(l)
                }
            })
        } catch (e: Exception) {
            logger.log(TAG, "Failed to set SDK logger: ${e.message}", "WARN")
        }
        logger.log(TAG, "Creating Breez foreground service...", "DEBUG")
        registerNotificationChannels(applicationContext, DEFAULT_CLICK_ACTION)
        logger.log(TAG, "Breez foreground service created.", "DEBUG")
    }

    override fun getConnectRequest(): ConnectRequest? {
        val apiKey = applicationContext.getString(R.string.breezApiKey)
        val config =
            defaultConfig(LiquidNetwork.MAINNET, apiKey).apply {
                workingDir = PathUtils.getDataDirectory(applicationContext)
            }

        return readSecuredValue(
            applicationContext,
            "${STORAGE_PREFIX}_$ACCOUNT_MNEMONIC",
        )?.let { ConnectRequest(config, it) }
    }

    companion object {
        private const val TAG = "BreezForegroundService"
        private const val ACCOUNT_MNEMONIC = "account_mnemonic"
        private const val DEFAULT_CLICK_ACTION = "FLUTTER_NOTIFICATION_CLICK"
        private const val STORAGE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg"
    }
}

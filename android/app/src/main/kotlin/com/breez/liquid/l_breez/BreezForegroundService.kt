package com.breez.liquid.l_breez

import android.content.SharedPreferences
import breez_sdk_liquid.ConnectRequest
import breez_sdk_liquid.LiquidNetwork
import breez_sdk_liquid.LogEntry
import breez_sdk_liquid.Logger as SdkLogger
import breez_sdk_liquid.defaultConfig
import breez_sdk_liquid.setLogger as setSdkLogger
import breez_sdk_liquid_notification.ForegroundService
import breez_sdk_liquid_notification.NotificationHelper.Companion.registerNotificationChannels
import com.breez.liquid.l_breez.utils.FlutterSecuredStorageHelper.Companion.readSecuredValue
import io.flutter.util.PathUtils
import org.tinylog.kotlin.Logger

class BreezForegroundService : SdkLogger, ForegroundService() {
    companion object {
        private const val TAG = "BreezForegroundService"

        private const val SHARED_PREFERENCES_NAME = "FlutterSharedPreferences"
        private const val ACCOUNT_MNEMONIC = "account_mnemonic"
        private const val DEFAULT_CLICK_ACTION = "FLUTTER_NOTIFICATION_CLICK"
        private const val ELEMENT_PREFERENCES_KEY_PREFIX =
            "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg"
    }

    override fun onCreate() {
        super.onCreate()
        setLogger(this)
        setSdkLogger(this)
        Logger.tag(TAG).debug { "Creating Breez foreground service..." }
        registerNotificationChannels(applicationContext, DEFAULT_CLICK_ACTION)
        Logger.tag(TAG).debug { "Breez foreground service created." }
    }

    override fun getConnectRequest(): ConnectRequest? {
        val config = defaultConfig(LiquidNetwork.MAINNET)

        config.workingDir = PathUtils.getDataDirectory(applicationContext)

        return readSecuredValue(
            applicationContext,
            "${ELEMENT_PREFERENCES_KEY_PREFIX}_${ACCOUNT_MNEMONIC}"
        )
            ?.let { mnemonic ->
                ConnectRequest(config, mnemonic)
            }
    }

    override fun log(l: LogEntry) {
        when (l.level) {
            "ERROR" -> Logger.tag(TAG).error { l.line }
            "WARN" -> Logger.tag(TAG).warn { l.line }
            "INFO" -> Logger.tag(TAG).info { l.line }
            "DEBUG" -> Logger.tag(TAG).debug { l.line }
            "TRACE" -> Logger.tag(TAG).trace { l.line }
        }
    }
}

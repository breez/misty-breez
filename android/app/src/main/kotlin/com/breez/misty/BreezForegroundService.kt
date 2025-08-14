package com.breez.misty

import android.content.SharedPreferences
import breez_sdk_liquid.ConnectRequest
import breez_sdk_liquid.LiquidNetwork
import breez_sdk_liquid.LogEntry
import breez_sdk_liquid.defaultConfig
import breez_sdk_liquid_notification.ForegroundService
import breez_sdk_liquid_notification.NotificationHelper.Companion.registerNotificationChannels
import com.breez.breez_sdk_liquid.SdkLogInitializer
import com.breez.breez_sdk_liquid.SdkLogListener
import com.breez.misty.utils.FlutterSecuredStorageHelper.Companion.readSecuredValue
import io.flutter.util.PathUtils
import org.tinylog.kotlin.Logger

class BreezForegroundService : ForegroundService() {
    companion object {
        private const val TAG = "BreezForegroundService"

        private const val SHARED_PREFERENCES_NAME = "FlutterSharedPreferences"
        private const val ACCOUNT_MNEMONIC = "account_mnemonic"
        private const val DEFAULT_CLICK_ACTION = "FLUTTER_NOTIFICATION_CLICK"
        private const val ELEMENT_PREFERENCES_KEY_PREFIX =
            "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg"
    }

    private var listener: SdkLogListener? = null

    override fun onCreate() {
        super.onCreate()
        Logger.tag(TAG).debug { "Creating Breez foreground service..." }
        registerNotificationChannels(applicationContext, DEFAULT_CLICK_ACTION)
        listener = SdkLogInitializer.initializeListener()
        listener?.let {
            it.subscribe(serviceScope) { l: LogEntry ->
                when (l.level) {
                    "ERROR" -> Logger.tag(TAG).error { l.line }
                    "WARN" -> Logger.tag(TAG).warn { l.line }
                    "INFO" -> Logger.tag(TAG).info { l.line }
                    "DEBUG" -> Logger.tag(TAG).debug { l.line }
                    // Ignore TRACE logs, they get filtered out by the logger
                }
            }
            setServiceLogger(it)
        }
        Logger.tag(TAG).debug { "Breez foreground service created." }
    }

    override fun onDestroy() {
        super.onDestroy()
        Logger.tag(TAG).debug { "Destroying Breez foreground service..." }
        listener?.unsubscribe(serviceScope)
        listener = null
    }

    override fun getConnectRequest(): ConnectRequest? {
        val apiKey = applicationContext.getString(R.string.breezApiKey)
        Logger.tag(TAG).trace { "API_KEY: $apiKey" }
        val config = defaultConfig(LiquidNetwork.MAINNET, apiKey)

        config.workingDir = PathUtils.getDataDirectory(applicationContext)        

        return readSecuredValue(
            applicationContext,
            "${ELEMENT_PREFERENCES_KEY_PREFIX}_${ACCOUNT_MNEMONIC}"
        )
            ?.let { mnemonic ->
                ConnectRequest(config, mnemonic)
            }
    }
}

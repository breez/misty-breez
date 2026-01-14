package com.breez.misty

import breez_sdk_liquid.ConnectRequest
import breez_sdk_liquid.LiquidNetwork
import breez_sdk_liquid.defaultConfig
import breez_sdk_liquid_notification.ForegroundService
import breez_sdk_liquid_notification.NotificationHelper.Companion.registerNotificationChannels
import com.breez.misty.utils.FlutterSecuredStorageHelper.Companion.readSecuredValue
import io.flutter.util.PathUtils

class BreezForegroundService : ForegroundService() {
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
        logger.log(TAG, "Creating Breez foreground service...", "DEBUG")
        registerNotificationChannels(applicationContext, DEFAULT_CLICK_ACTION)
        logger.log(TAG, "Breez foreground service created.", "DEBUG")
    }

    override fun onDestroy() {
        super.onDestroy()
        logger.log(TAG, "Destroying Breez foreground service...", "DEBUG")
    }

    override fun getConnectRequest(): ConnectRequest? {
        val apiKey = applicationContext.getString(R.string.breezApiKey)
        logger.log(TAG, "API_KEY: $apiKey", "TRACE")
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

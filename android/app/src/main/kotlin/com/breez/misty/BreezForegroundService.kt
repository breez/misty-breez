package com.breez.misty

import breez_sdk_liquid.ConnectRequest
import breez_sdk_liquid.LiquidNetwork
import breez_sdk_liquid.defaultConfig
import breez_sdk_liquid_notification.ForegroundService
import breez_sdk_liquid_notification.NotificationHelper.Companion.registerNotificationChannels
import com.breez.misty.utils.readSecuredValue
import io.flutter.util.PathUtils

class BreezForegroundService : ForegroundService() {
    override fun onCreate() {
        super.onCreate()
        registerNotificationChannels(applicationContext, DEFAULT_CLICK_ACTION)
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
        private const val ACCOUNT_MNEMONIC = "account_mnemonic"
        private const val DEFAULT_CLICK_ACTION = "FLUTTER_NOTIFICATION_CLICK"
        private const val STORAGE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg"
    }
}

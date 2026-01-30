package com.breez.misty.utils

import android.content.Context
import android.util.Base64

private const val PREFS_NAME = "FlutterSecureStorage"

fun readSecuredValue(
    context: Context,
    key: String,
): String? {
    val rawValue =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).getString(key, null) ?: return null

    val data = Base64.decode(rawValue, Base64.DEFAULT)
    val keyCipher = RSACipher18Implementation(context)
    val storageCipher = StorageCipher18Implementation(context, keyCipher)
    return String(storageCipher.decrypt(data), Charsets.UTF_8)
}

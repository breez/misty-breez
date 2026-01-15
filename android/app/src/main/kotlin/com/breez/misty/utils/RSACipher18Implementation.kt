package com.breez.misty.utils

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.math.BigInteger
import java.security.Key
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.util.Calendar
import java.util.Locale
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.security.auth.x500.X500Principal

internal class RSACipher18Implementation(
    context: Context,
) {
    private val keyAlias = "${context.packageName}.FlutterSecureStoragePluginKey"

    init {
        createRSAKeysIfNeeded(context)
    }

    fun unwrap(
        wrappedKey: ByteArray,
        algorithm: String,
    ): Key {
        val cipher = Cipher.getInstance(RSA_TRANSFORMATION, RSA_PROVIDER)
        cipher.init(Cipher.UNWRAP_MODE, getPrivateKey())
        return cipher.unwrap(wrappedKey, algorithm, Cipher.SECRET_KEY)
    }

    private fun getPrivateKey(): PrivateKey {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        return keyStore.getKey(keyAlias, null) as? PrivateKey
            ?: throw IllegalStateException("No private key found under alias: $keyAlias")
    }

    private fun createRSAKeysIfNeeded(context: Context) {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        if (keyStore.getKey(keyAlias, null) == null) {
            createKeys(context)
        }
    }

    private fun createKeys(context: Context) {
        val originalLocale = Locale.getDefault()
        try {
            // Temporarily set English locale to work around KeyPairGenerator bugs
            setLocale(context, Locale.ENGLISH)

            val start = Calendar.getInstance()
            val end = Calendar.getInstance().apply { add(Calendar.YEAR, 25) }

            val spec =
                KeyGenParameterSpec
                    .Builder(
                        keyAlias,
                        KeyProperties.PURPOSE_DECRYPT or KeyProperties.PURPOSE_ENCRYPT,
                    ).setCertificateSubject(X500Principal("CN=$keyAlias"))
                    .setDigests(KeyProperties.DIGEST_SHA256)
                    .setBlockModes(KeyProperties.BLOCK_MODE_ECB)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1)
                    .setCertificateSerialNumber(BigInteger.ONE)
                    .setCertificateNotBefore(start.time)
                    .setCertificateNotAfter(end.time)
                    .build()

            KeyPairGenerator.getInstance(TYPE_RSA, KEYSTORE_PROVIDER).apply {
                initialize(spec)
                generateKeyPair()
            }
        } finally {
            setLocale(context, originalLocale)
        }
    }

    private fun setLocale(
        context: Context,
        locale: Locale,
    ) {
        Locale.setDefault(locale)
        context.resources.configuration.let { config ->
            config.setLocale(locale)
            context.createConfigurationContext(config)
        }
    }

    companion object {
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val TYPE_RSA = "RSA"
        private const val RSA_TRANSFORMATION = "RSA/ECB/PKCS1Padding"
        private const val RSA_PROVIDER = "AndroidKeyStoreBCWorkaround"
    }
}

internal class StorageCipher18Implementation(
    private val context: Context,
    private val rsaCipher: RSACipher18Implementation,
) {
    fun decrypt(input: ByteArray): ByteArray {
        val iv = input.copyOfRange(0, IV_SIZE)
        val payload = input.copyOfRange(IV_SIZE, input.size)

        val cipher =
            Cipher.getInstance(AES_TRANSFORMATION).apply {
                init(Cipher.DECRYPT_MODE, getKey(), IvParameterSpec(iv))
            }
        return cipher.doFinal(payload)
    }

    private fun getKey(): Key {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val aesKeyEncoded =
            prefs.getString(AES_PREFS_KEY, null) ?: throw IllegalStateException("AES key not found")

        val encrypted = Base64.decode(aesKeyEncoded, Base64.DEFAULT)
        return rsaCipher.unwrap(encrypted, KEY_ALGORITHM)
    }

    companion object {
        private const val IV_SIZE = 16
        private const val KEY_ALGORITHM = "AES"
        private const val AES_TRANSFORMATION = "AES/CBC/PKCS7Padding"
        private const val PREFS_NAME = "FlutterSecureKeyStorage"
        private const val AES_PREFS_KEY = "VGhpcyBpcyB0aGUga2V5IGZvciBhIHNlY3VyZSBzdG9yYWdlIEFFUyBLZXkK"
    }
}

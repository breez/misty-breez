package com.breez.misty

import android.content.Context
import io.flutter.util.PathUtils
import org.tinylog.kotlin.Logger
import java.io.File

class BreezLogger {
    companion object {
        private const val TAG = "BreezLogger"

        private var isInit: Boolean? = null

        internal fun configureLogger(applicationContext: Context): Boolean? {
            synchronized(this) {
                /** Get `/logs` folder from Flutter app data directory */
                val loggingDir =
                    File(PathUtils.getDataDirectory(applicationContext), "/logs").apply {
                        /** Create a new directory denoted by the pathname and also
                         *  all the non existent parent directories of the pathname */
                        mkdirs()
                    }

                System.setProperty("tinylog.directory", loggingDir.absolutePath)
                System.setProperty("tinylog.timestamp", System.currentTimeMillis().toString())

                if (isInit == false) {
                    val applicationId = applicationContext.packageName
                    Logger.tag(TAG).debug { "Starting $applicationId..." }
                    Logger.tag(TAG).debug { "Logs directory: '$loggingDir'" }
                    isInit = true
                }
                return isInit
            }
        }
    }
}
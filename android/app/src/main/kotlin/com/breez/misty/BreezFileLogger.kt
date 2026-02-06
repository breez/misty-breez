package com.breez.misty

import android.content.Context
import breez_sdk_liquid.LogEntry
import breez_sdk_liquid.Logger
import io.flutter.util.PathUtils
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class BreezFileLogger private constructor(
    private val context: Context,
    var minLevel: LogLevel = LogLevel.TRACE,
) : Logger {
    private var logFile: File? = null

    enum class LogLevel(val priority: Int) {
        TRACE(0),
        DEBUG(1),
        INFO(2),
        WARN(3),
        ERROR(4),
        ;

        companion object {
            fun fromString(level: String): LogLevel =
                entries.find { it.name.equals(level, ignoreCase = true) } ?: TRACE
        }
    }

    companion object {
        private const val TAG = "BreezFileLogger"

        @Volatile
        private var instance: BreezFileLogger? = null

        fun getInstance(context: Context): BreezFileLogger {
            return instance ?: synchronized(this) {
                instance ?: BreezFileLogger(context.applicationContext).also { instance = it }
            }
        }
    }

    init {
        try {
            // Use Flutter's data directory to match the app-side logs location
            val workingDir = PathUtils.getDataDirectory(context)
            val logsDir = File(workingDir, "logs")
            if (!logsDir.exists()) {
                logsDir.mkdirs()
            }
            val timestamp = System.currentTimeMillis()
            logFile = File(logsDir, "$timestamp.android-extension.log")
            logFile?.createNewFile()
            android.util.Log.i(TAG, "Created log file at: ${logFile?.absolutePath}")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to create log file: ${e.message}", e)
        }
    }

    override fun log(l: LogEntry) {
        if (LogLevel.fromString(l.level).priority >= minLevel.priority) {
            logToFile(l.line, l.level)
        }
    }

    private fun logToFile(message: String, level: String) {
        try {
            logFile?.let {
                val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
                FileWriter(it, true).use { writer ->
                    writer.write("$timestamp $level: $message\n")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed to write to log file: ${e.message}")
        }
    }
}

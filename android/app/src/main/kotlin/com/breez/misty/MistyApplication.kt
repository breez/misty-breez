package com.breez.misty

import android.app.ActivityManager
import android.app.Application
import android.os.Build
import android.os.Process
import android.system.Os
import io.flutter.util.PathUtils
import java.io.File
import java.io.FileOutputStream

/**
 * Keeps evidence of native crashes in the shared logs folder, where "Share logs" picks it up.
 *
 * The SDK aborts on a Rust panic, printing the panic message to stderr, which Android discards,
 * and the Dart side never gets to log anything. Files use .txt so log pruning leaves them alone.
 */
class MistyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val logsDir = File(PathUtils.getDataDirectory(this), "logs").apply { mkdirs() }
        redirectStderr(File(logsDir, "native_stderr.txt"))
        recordExitReasons(File(logsDir, "exit_reasons.txt"))
    }

    private fun redirectStderr(file: File) {
        runCatching {
            // ponytail: starts over past 1 MB instead of rotating.
            val out = FileOutputStream(file, file.length() < 1_000_000)
            out.write("--- pid ${Process.myPid()} started at ${System.currentTimeMillis()}\n".toByteArray())
            Os.dup2(out.fd, 2)
        }
    }

    /** Why recent processes died: signal for native crashes, LOW_MEMORY for the memory killer. */
    private fun recordExitReasons(file: File) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            runCatching {
                val reasons = getSystemService(ActivityManager::class.java)
                    ?.getHistoricalProcessExitReasons(packageName, 0, 10)
                    .orEmpty()
                file.writeText(reasons.joinToString("\n"))
            }
        }
    }
}

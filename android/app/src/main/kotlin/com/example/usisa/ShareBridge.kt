package com.example.usisa

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.util.UUID
import java.util.concurrent.Executors

/** Copies at most [limit] bytes; false (and no file left) when the stream is larger or fails. */
fun copyCapped(input: InputStream, dest: File, limit: Long = 20L * 1024 * 1024): Boolean = try {
    dest.parentFile?.mkdirs()
    input.use { inp ->
        dest.outputStream().use { out ->
            val buf = ByteArray(64 * 1024)
            var total = 0L
            while (true) {
                val n = inp.read(buf)
                if (n < 0) break
                total += n
                if (total > limit) throw IOException("too large")
                out.write(buf, 0, n)
            }
        }
    }
    true
} catch (_: Exception) { dest.delete(); false }

/**
 * ACTION_SEND into Usisa over `usisa/share`. Holds one share until Dart calls `take`,
 * and pings `shared` when one arrives while the app is open. Images are copied into the
 * app cache right away because the sender's read grant ends with this activity.
 */
class ShareBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "usisa/share")
    private val io = Executors.newSingleThreadExecutor() // FIFO: a `take` always runs after the copy before it.
    private val main = Handler(Looper.getMainLooper())
    private var pending: Map<String, String>? = null // Only touched on [io].
    @Volatile private var disposed = false

    init {
        channel.setMethodCallHandler { call, reply ->
            if (call.method != "take") { reply.notImplemented(); return@setMethodCallHandler }
            io.execute { val value = pending; pending = null; main.post { if (!disposed) reply.success(value) } }
        }
    }

    fun capture(intent: Intent?, notify: Boolean) {
        if (intent?.action != Intent.ACTION_SEND) return
        // Recents can re-deliver the original share; don't open it again.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        val uri = if (intent.type?.startsWith("image/") == true) stream(intent) else null
        intent.action = null // Taken once; a recreate must not open it again.
        if (uri == null && text.isNullOrBlank()) return
        io.execute {
            // A mixed share prefers the image; its caption is used only if the image can't be copied.
            val item = uri?.let(::copy)?.let { mapOf("image" to it) } ?: text?.takeIf { it.isNotBlank() }?.let { mapOf("text" to it) }
            pending = item ?: return@execute
            if (notify) main.post { if (!disposed) channel.invokeMethod("shared", null) }
        }
    }

    private fun stream(intent: Intent): Uri? {
        val uri = if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
        // The sender is untrusted: only its own content, never file:// or our own providers.
        if (uri?.scheme != "content" || uri.authority?.startsWith(activity.packageName) != false) return null
        return uri
    }

    private fun copy(uri: Uri): String? {
        val dir = File(activity.cacheDir, "shared")
        dir.listFiles()?.forEach { it.delete() } // Keep only the latest share.
        val dest = File(dir, UUID.randomUUID().toString())
        val input = try { activity.contentResolver.openInputStream(uri) } catch (_: Exception) { null } ?: return null
        return if (copyCapped(input, dest)) dest.absolutePath else null
    }

    fun dispose() { disposed = true; channel.setMethodCallHandler(null); io.shutdown() }
}

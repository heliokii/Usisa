package com.example.usisa

import android.os.Handler
import android.os.Looper
import androidx.work.WorkManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import org.json.JSONArray
import org.json.JSONObject

class SmsBridge(private val activity: MainActivity, messenger: BinaryMessenger) {
    companion object { var onStateChanged: (() -> Unit)? = null }
    private val channel = MethodChannel(messenger, "usisa/sms")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val store = PendingSmsStore(activity)
    @Volatile private var disposed = false
    private val changed: () -> Unit = { channel.invokeMethod("statusChanged", null) }
    init {
        onStateChanged = changed
        channel.setMethodCallHandler { call, reply ->
            if (call.method == "requestPermissions") { activity.requestSmsPermissions(reply); return@setMethodCallHandler }
            if (call.method == "requestNotifications") { activity.requestSmsPermissions(reply, true); return@setMethodCallHandler }
            io.execute {
                try {
                    val value: Any? = when (call.method) {
                        "status" -> status()
                        "setEnabled" -> {
                            val enable = call.argument<Boolean>("enabled") == true && SmsReceiver.permitted(activity)
                            synchronized(PendingSmsStore.lock) {
                                store.setEnabled(enable, call.argument<String>("language") ?: "en")
                                if (!enable) WorkManager.getInstance(activity).cancelAllWorkByTag(SmsCheckWorker.TAG)
                            }
                            status()
                        }
                        "invalidate" -> synchronized(PendingSmsStore.lock) {
                            val next = store.invalidate()
                            WorkManager.getInstance(activity).cancelAllWorkByTag(SmsCheckWorker.TAG)
                            next
                        }
                        "language" -> { store.setLanguage(call.arguments as? String ?: "en"); null }
                        "reviews" -> if (BuildConfig.SMS_ENABLED) store.reviews() else emptyList<String>()
                        "review" -> {
                            val id = call.arguments as? String
                            val item = if (BuildConfig.SMS_ENABLED && id != null) store.read(id) else null
                            if (item == null) null else mapOf("body" to item.getString("body"), "generation" to item.getLong("generation"),
                                "result" to jsonValue(item.optJSONObject("result")),
                                "error" to if (item.has("result")) null else item.optString("error", "pending"))
                        }
                        "takeNotification" -> activity.takeNotification()
                        else -> { main.post { reply.notImplemented() }; return@execute }
                    }
                    main.post { if (!disposed) reply.success(value) }
                } catch (_: Exception) { main.post { if (!disposed) reply.error("sms_unavailable", "SMS operation could not finish", null) } }
            }
        }
    }
    private fun status(): Map<String, Any> {
        val permitted = SmsReceiver.permitted(activity)
        return mapOf("supported" to BuildConfig.SMS_ENABLED, "enabled" to (store.enabled && permitted), "smsPermission" to permitted,
            "notifications" to (BuildConfig.SMS_ENABLED && SmsAlerts.allowed(activity)), "generation" to store.generation,
            "degraded" to store.degraded, "pending" to if (BuildConfig.SMS_ENABLED) store.reviews().size else 0)
    }
    private fun jsonValue(value: Any?): Any? = when (value) {
        null, JSONObject.NULL -> null
        is JSONObject -> value.keys().asSequence().associateWith { jsonValue(value.get(it)) }
        is JSONArray -> (0 until value.length()).map { jsonValue(value.get(it)) }
        else -> value
    }
    fun notifyOpen(id: String) { channel.invokeMethod("notification", id) }
    fun dispose() { disposed = true; if (onStateChanged === changed) onStateChanged = null; channel.setMethodCallHandler(null); io.shutdown() }
}

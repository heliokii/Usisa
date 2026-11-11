package com.example.usisa

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.Worker
import androidx.work.workDataOf
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import org.json.JSONObject

class SmsCheckWorker(context: Context, parameters: WorkerParameters) : CoroutineWorker(context, parameters) {
    companion object {
        const val TAG = "usisa_sms_check"
        private val engineMutex = Mutex()
        fun enqueue(context: Context, id: String) {
            val work = OneTimeWorkRequestBuilder<SmsCheckWorker>().setInputData(workDataOf("eventId" to id))
                .addTag(TAG).setBackoffCriteria(androidx.work.BackoffPolicy.LINEAR, 10, TimeUnit.SECONDS).build()
            WorkManager.getInstance(context).enqueueUniqueWork("usisa-$id", ExistingWorkPolicy.KEEP, work)
            val expiry = OneTimeWorkRequestBuilder<SmsExpiryWorker>().setInputData(workDataOf("eventId" to id))
                .setInitialDelay(SmsPolicy.TTL_MS, TimeUnit.MILLISECONDS).addTag(TAG).build()
            WorkManager.getInstance(context).enqueueUniqueWork("usisa-expiry-$id", ExistingWorkPolicy.KEEP, expiry)
        }
    }
    override suspend fun doWork(): Result = engineMutex.withLock {
        val id = inputData.getString("eventId") ?: return@withLock Result.failure()
        val store = PendingSmsStore(applicationContext)
        val event = store.read(id) ?: return@withLock Result.success()
        if (!SmsReceiver.permitted(applicationContext) || !store.enabled) { store.remove(id); return@withLock Result.success() }
        val payload = try { withTimeout(30000) { evaluate(event) } }
        catch (_: TimeoutCancellationException) {
            if (runAttemptCount < 1) return@withLock Result.retry()
            JSONObject().put("error", "scanFailed")
        } catch (cancel: CancellationException) { throw cancel }
        catch (_: Exception) {
            if (runAttemptCount < 1) return@withLock Result.retry()
            JSONObject().put("error", "scanFailed")
        }
        synchronized(PendingSmsStore.lock) {
            if (SmsReceiver.permitted(applicationContext) && store.complete(id, event.getLong("generation"), payload)) {
                if (payload.optString("risk") != "low") SmsAlerts.show(applicationContext, id, payload.has("error"))
            }
        }
        Handler(Looper.getMainLooper()).post { SmsBridge.onStateChanged?.invoke() }
        Result.success()
    }
    private suspend fun evaluate(event: JSONObject): JSONObject = withContext(Dispatchers.Main) {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val engine = FlutterEngine(applicationContext, null, false)
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "usisa/sms_worker")
        val completion = CompletableDeferred<JSONObject>()
        channel.setMethodCallHandler { call, reply ->
            when (call.method) {
                "takeEvent" -> reply.success(mapOf("id" to event.getString("id"), "body" to event.getString("body"), "generation" to event.getLong("generation")))
                "complete" -> {
                    try {
                        val payload = JSONObject(call.arguments as Map<*, *>)
                        require(payload.toString().toByteArray().size <= 128 * 1024)
                        if (payload.has("result")) {
                            val result = payload.getJSONObject("result")
                            require(result.getString("id") == event.getString("id") && result.getString("text") == event.getString("body"))
                            require(result.getString("source") == "sms" && payload.getString("risk") in listOf("low", "caution", "high"))
                        } else require(payload.optString("error") in listOf("emptyInput", "textTooLong", "urlTooLong", "tooManyLinks", "scanFailed"))
                        reply.success(null); completion.complete(payload)
                    } catch (_: Exception) { reply.error("invalid_result", "Background result was invalid", null); completion.completeExceptionally(IllegalStateException("Invalid background result")) }
                }
                else -> reply.notImplemented()
            }
        }
        try {
            engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "usisaSmsBackground"))
            completion.await()
        } finally { channel.setMethodCallHandler(null); engine.destroy() }
    }
}

class SmsExpiryWorker(context: Context, parameters: WorkerParameters) : Worker(context, parameters) {
    override fun doWork(): Result {
        val id = inputData.getString("eventId") ?: return Result.failure()
        return try {
            PendingSmsStore(applicationContext).read(id)
            Result.success()
        } catch (_: Exception) { Result.retry() }
    }
}

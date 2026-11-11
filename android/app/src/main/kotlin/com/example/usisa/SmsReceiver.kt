package com.example.usisa

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Telephony
import android.telephony.SubscriptionManager
import java.util.concurrent.Executors

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private val io = Executors.newSingleThreadExecutor()
        fun permitted(context: Context) = BuildConfig.SMS_ENABLED &&
            context.checkSelfPermission(Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
    }
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION || !permitted(context)) return
        val store = PendingSmsStore(context)
        val receiptGeneration = synchronized(PendingSmsStore.lock) { if (!store.enabled) return; store.generation }
        val receivedAt = System.currentTimeMillis()
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        if (messages.isEmpty() || messages.map { it.originatingAddress }.distinct().size != 1) return
        val pdus = intent.extras?.get("pdus") as? Array<*> ?: return
        val bytes = pdus.mapNotNull { it as? ByteArray }
        if (bytes.size != pdus.size || bytes.isEmpty()) return
        val id = SmsPolicy.eventId(bytes, intent.getIntExtra(SubscriptionManager.EXTRA_SUBSCRIPTION_INDEX, -1))
        val body = messages.joinToString("") { it.messageBody.orEmpty() }
        val pending = goAsync()
        io.execute {
            try {
                when (store.put(id, body, receiptGeneration, receivedAt)) {
                    PendingSmsStore.PutResult.ADDED -> SmsCheckWorker.enqueue(context, id)
                    PendingSmsStore.PutResult.FULL -> synchronized(PendingSmsStore.lock) {
                        if (SmsPolicy.canCommit(receiptGeneration, store.generation, store.enabled) && permitted(context)) SmsAlerts.show(context, "queue-limit", true)
                    }
                    else -> Unit
                }
            } catch (_: Exception) {
                synchronized(PendingSmsStore.lock) {
                    if (SmsPolicy.canCommit(receiptGeneration, store.generation, store.enabled) && permitted(context)) {
                        store.markDegraded(); SmsAlerts.show(context, "queue-error", true)
                    }
                }
            }
            finally { pending.finish() }
        }
    }
}

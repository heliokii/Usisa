package com.example.usisa

import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import android.content.Context
import java.io.File
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PendingSmsStoreTest {
    @Test fun encryptedQueueExpiresAndRefusesStaleCommits() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        var now = 1000L
        val store = PendingSmsStore(context, "sms_test") { now }
        store.setEnabled(false, "en")
        store.setEnabled(true, "en")
        val id = SmsPolicy.eventId(listOf(byteArrayOf(1, 2, 3)), 1)
        val body = "Synthetic private message: share your OTP"
        assertEquals(PendingSmsStore.PutResult.ADDED, store.put(id, body))
        assertEquals(PendingSmsStore.PutResult.DUPLICATE, store.put(id, body))
        assertEquals(body, store.read(id)!!.getString("body"))
        val raw = File(context.noBackupFilesDir, "sms_test/$id.bin").readBytes().toString(Charsets.UTF_8)
        assertFalse(raw.contains(body))
        val generation = store.generation
        store.invalidate()
        assertFalse(store.complete(id, generation, JSONObject().put("error", "synthetic")))
        assertNull(store.read(id))
        val other = SmsPolicy.eventId(listOf(byteArrayOf(4, 5, 6)), 1)
        assertEquals(PendingSmsStore.PutResult.ADDED, store.put(other, body))
        now += SmsPolicy.TTL_MS
        assertNull(store.read(other))
        store.setEnabled(false, "en")
    }

    @Test fun boundedQueueDoesNotDeduplicateDistinctSameTextMessages() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = PendingSmsStore(context, "sms_test_bound")
        store.setEnabled(false, "en")
        store.setEnabled(true, "en")
        repeat(20) { index ->
            val id = SmsPolicy.eventId(listOf(byteArrayOf(index.toByte())), 1)
            assertEquals(PendingSmsStore.PutResult.ADDED, store.put(id, "Same text"))
        }
        assertEquals(PendingSmsStore.PutResult.FULL, store.put(SmsPolicy.eventId(listOf(byteArrayOf(100)), 1), "Same text"))
        assertTrue(store.degraded)
        store.setEnabled(false, "en")
        assertEquals(PendingSmsStore.PutResult.DISABLED, store.put(SmsPolicy.eventId(listOf(byteArrayOf(101)), 1), "Not retained"))
    }
}

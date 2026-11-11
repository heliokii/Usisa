package com.example.usisa

import java.nio.ByteBuffer
import java.security.MessageDigest
import java.util.UUID

object SmsPolicy {
    const val MAX_EVENTS = 20
    const val TTL_MS = 15 * 60 * 1000L
    fun isLive(receivedAt: Long, now: Long) = now >= receivedAt && now - receivedAt < TTL_MS
    fun canCommit(expected: Long, actual: Long, enabled: Boolean) = enabled && expected == actual
    fun eventId(pdus: List<ByteArray>, subscription: Int): String {
        val digest = MessageDigest.getInstance("SHA-256")
        digest.update(ByteBuffer.allocate(4).putInt(subscription).array())
        for (pdu in pdus) { digest.update(ByteBuffer.allocate(4).putInt(pdu.size).array()); digest.update(pdu) }
        return UUID.nameUUIDFromBytes(digest.digest()).toString()
    }
}

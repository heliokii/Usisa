package com.example.usisa

import java.nio.ByteBuffer
import java.security.MessageDigest
import java.util.TimeZone
import java.util.UUID

object SmsPolicy {
    const val MAX_EVENTS = 20
    // A delayed check still runs (and can still notify) while the text is under 24 hours old.
    const val TTL_MS = 24 * 60 * 60 * 1000L
    fun isLive(receivedAt: Long, now: Long) = now >= receivedAt && now - receivedAt < TTL_MS
    fun canCommit(expected: Long, actual: Long, enabled: Boolean) = enabled && expected == actual
    /** Joins the parts of one multipart text in delivery order; null when parts disagree on the sender. */
    fun join(parts: List<Pair<String?, String?>>): Pair<String?, String>? {
        if (parts.isEmpty() || parts.map { it.first }.distinct().size != 1) return null
        return parts[0].first to parts.joinToString("") { it.second.orEmpty() }
    }
    /** Local calendar day, so "checked today" resets at the phone's midnight. */
    fun day(ms: Long, zone: TimeZone = TimeZone.getDefault()) = Math.floorDiv(ms + zone.getOffset(ms), 86_400_000L)
    fun eventId(pdus: List<ByteArray>, subscription: Int): String {
        val digest = MessageDigest.getInstance("SHA-256")
        digest.update(ByteBuffer.allocate(4).putInt(subscription).array())
        for (pdu in pdus) { digest.update(ByteBuffer.allocate(4).putInt(pdu.size).array()); digest.update(pdu) }
        return UUID.nameUUIDFromBytes(digest.digest()).toString()
    }
}

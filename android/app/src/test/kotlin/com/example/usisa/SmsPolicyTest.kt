package com.example.usisa

import java.util.TimeZone
import org.junit.Assert.*
import org.junit.Test

class SmsPolicyTest {
    private val hour = 60 * 60 * 1000L

    @Test fun expiryAndGenerationAreRequiredToCommit() {
        assertTrue(SmsPolicy.isLive(1000, 2000))
        assertFalse(SmsPolicy.isLive(1000, 1000 + SmsPolicy.TTL_MS))
        assertFalse(SmsPolicy.isLive(100000, 0))
        assertTrue(SmsPolicy.canCommit(3, 3, true))
        assertFalse(SmsPolicy.canCommit(3, 4, true))
        assertFalse(SmsPolicy.canCommit(3, 3, false))
        assertEquals(20, SmsPolicy.MAX_EVENTS)
    }

    @Test fun delayedTextUnder24HoursIsStillCheckedButNotAfter() {
        val received = 1_000_000L
        assertTrue(SmsPolicy.isLive(received, received + 16 * 60 * 1000L))
        assertTrue(SmsPolicy.isLive(received, received + 23 * hour + 59 * 60 * 1000L))
        assertFalse(SmsPolicy.isLive(received, received + 24 * hour))
    }

    @Test fun multipartTextIsJoinedInOrderFromOneSender() {
        val parts = listOf("GCASH" to "Your account is locked. Verify within 1 hour at ", "GCASH" to "http://gcash-verify.example", "GCASH" to null)
        assertEquals("GCASH" to "Your account is locked. Verify within 1 hour at http://gcash-verify.example", SmsPolicy.join(parts))
    }

    @Test fun partsFromDifferentSendersOrNoPartsAreNotJoined() {
        assertNull(SmsPolicy.join(listOf("GCASH" to "Hi ", "09171234567" to "there")))
        assertNull(SmsPolicy.join(emptyList()))
    }

    @Test fun dailyCountResetsAtLocalMidnight() {
        val manila = TimeZone.getTimeZone("Asia/Manila")
        // 2026-11-21 23:30 and 2026-11-22 00:30 in Manila (UTC+8).
        val lateNight = 1795275000000L
        assertEquals(SmsPolicy.day(lateNight, manila), SmsPolicy.day(lateNight - 20 * hour, manila))
        assertNotEquals(SmsPolicy.day(lateNight, manila), SmsPolicy.day(lateNight + hour, manila))
    }

    @Test fun deliveredPdusDeduplicateWithoutDroppingDistinctMessages() {
        val pdus = listOf(byteArrayOf(1, 2, 3))
        assertEquals(SmsPolicy.eventId(pdus, 1), SmsPolicy.eventId(pdus, 1))
        assertNotEquals(SmsPolicy.eventId(pdus, 1), SmsPolicy.eventId(pdus, 2))
        assertNotEquals(SmsPolicy.eventId(pdus, 1), SmsPolicy.eventId(listOf(byteArrayOf(1, 2, 4)), 1))
    }
}

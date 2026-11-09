package com.example.usisa

import org.junit.Assert.*
import org.junit.Test

class SmsPolicyTest {
    @Test fun expiryAndGenerationAreRequiredToCommit() {
        assertTrue(SmsPolicy.isLive(1000, 2000))
        assertFalse(SmsPolicy.isLive(1000, 1000 + SmsPolicy.TTL_MS))
        assertFalse(SmsPolicy.isLive(100000, 0))
        assertTrue(SmsPolicy.canCommit(3, 3, true))
        assertFalse(SmsPolicy.canCommit(3, 4, true))
        assertFalse(SmsPolicy.canCommit(3, 3, false))
        assertEquals(20, SmsPolicy.MAX_EVENTS)
    }
    @Test fun deliveredPdusDeduplicateWithoutDroppingDistinctMessages() {
        val pdus = listOf(byteArrayOf(1, 2, 3))
        assertEquals(SmsPolicy.eventId(pdus, 1), SmsPolicy.eventId(pdus, 1))
        assertNotEquals(SmsPolicy.eventId(pdus, 1), SmsPolicy.eventId(pdus, 2))
        assertNotEquals(SmsPolicy.eventId(pdus, 1), SmsPolicy.eventId(listOf(byteArrayOf(1, 2, 4)), 1))
    }
}

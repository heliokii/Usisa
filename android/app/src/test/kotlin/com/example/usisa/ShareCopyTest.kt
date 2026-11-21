package com.example.usisa

import java.io.ByteArrayInputStream
import java.io.File
import java.nio.file.Files
import org.junit.Assert.*
import org.junit.Test

class ShareCopyTest {
    private val cache = Files.createTempDirectory("usisa-cache").toFile()

    @Test fun aSharedImageIsCopiedIntoTheCache() {
        val dest = File(cache, "shared/a")
        assertTrue(copyCapped(ByteArrayInputStream(byteArrayOf(1, 2, 3)), dest, limit = 3))
        assertArrayEquals(byteArrayOf(1, 2, 3), dest.readBytes())
    }

    @Test fun anOversizedStreamLeavesNoFile() {
        val dest = File(cache, "shared/b")
        assertFalse(copyCapped(ByteArrayInputStream(ByteArray(4)), dest, limit = 3))
        assertFalse(dest.exists())
    }
}

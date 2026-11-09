package com.example.usisa

import android.app.NotificationManager
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import java.io.File
import java.io.IOException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import org.json.JSONObject

class PendingSmsStore(context: Context, namespace: String = "sms", private val clock: () -> Long = System::currentTimeMillis) {
    init { require(namespace.matches(Regex("[a-z0-9_]{1,40}"))) }
    private val context = context.applicationContext
    private val directory = File(context.noBackupFilesDir, namespace)
    private val prefs = context.getSharedPreferences("usisa_$namespace", Context.MODE_PRIVATE)
    private val alias = "usisa.$namespace"
    val generation: Long get() = synchronized(lock) { prefs.getLong("generation", 0) }
    val enabled: Boolean get() = synchronized(lock) { prefs.getBoolean("enabled", false) }
    val degraded: Boolean get() = synchronized(lock) { prefs.getBoolean("degraded", false) }
    val language: String get() = synchronized(lock) { prefs.getString("language", "en") ?: "en" }
    enum class PutResult { ADDED, DUPLICATE, FULL, DISABLED }
    companion object {
        val lock = Any()
        private val idPattern = Regex("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
    }
    private fun file(id: String): AtomicFile {
        require(idPattern.matches(id))
        return AtomicFile(File(directory, "$id.bin"))
    }
    private fun ids(): List<String> = directory.listFiles().orEmpty().mapNotNull {
        val id = it.name.substringBefore(".bin")
        if (idPattern.matches(id)) id else null
    }.distinct()
    fun setLanguage(value: String) = synchronized(lock) {
        check(prefs.edit().putString("language", if (value == "fil") "fil" else "en").commit())
    }
    fun markDegraded() = synchronized(lock) { prefs.edit().putBoolean("degraded", true).commit(); Unit }
    fun setEnabled(value: Boolean, language: String) = synchronized(lock) {
        setLanguage(language)
        check(prefs.edit().putBoolean("enabled", value).commit())
        if (!value) invalidate() else check(prefs.edit().putBoolean("degraded", false).commit())
        Unit
    }
    fun invalidate(): Long = synchronized(lock) {
        val next = generation + 1
        check(prefs.edit().putLong("generation", next).putBoolean("degraded", false).remove("seen").commit())
        val notifications = context.getSystemService(NotificationManager::class.java)
        for (id in ids()) { remove(id); notifications.cancel(id, 1) }
        notifications.cancel("queue-limit", 1); notifications.cancel("queue-error", 1)
        next
    }
    fun remove(id: String) = synchronized(lock) {
        file(id).delete()
        if (File(directory, "$id.bin").exists()) throw IOException("Cannot erase temporary scan")
        Unit
    }
    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true).build())
        }.generateKey()
    }
    private fun write(id: String, value: JSONObject) {
        if (!directory.exists() && !directory.mkdirs()) throw IOException("Cannot create private queue")
        val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key()) }
        val bytes = cipher.iv + cipher.doFinal(value.toString().toByteArray(Charsets.UTF_8))
        val target = file(id)
        val output = target.startWrite()
        try { output.write(bytes); target.finishWrite(output) }
        catch (error: Throwable) { target.failWrite(output); throw error }
    }
    fun read(id: String): JSONObject? = synchronized(lock) {
        if (!idPattern.matches(id)) return@synchronized null
        if (!file(id).baseFile.exists() && !File(directory, "$id.bin.bak").exists()) return@synchronized null
        try {
            val bytes = file(id).openRead().use { it.readBytes() }
            require(bytes.size in 29..160000)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply {
                init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes.copyOfRange(0, 12)))
            }
            val value = JSONObject(String(cipher.doFinal(bytes.copyOfRange(12, bytes.size)), Charsets.UTF_8))
            if (!SmsPolicy.isLive(value.getLong("receivedAt"), clock()) || value.getLong("generation") != generation) {
                remove(id); context.getSystemService(NotificationManager::class.java).cancel(id, 1); return@synchronized null
            }
            value
        } catch (_: Exception) { remove(id); markDegraded(); null }
    }
    fun put(id: String, body: String): PutResult = synchronized(lock) {
        if (!enabled) return@synchronized PutResult.DISABLED
        require(idPattern.matches(id))
        val seen = try { JSONObject(prefs.getString("seen", "{}")!!) } catch (_: Exception) { JSONObject() }
        val now = clock()
        seen.keys().asSequence().toList().filter { !SmsPolicy.isLive(seen.optLong(it), now) }.forEach { seen.remove(it) }
        if (seen.has(id)) return@synchronized PutResult.DUPLICATE
        for (old in ids()) read(old)
        if (ids().size >= SmsPolicy.MAX_EVENTS || body.codePointCount(0, body.length) > 10000) {
            markDegraded(); return@synchronized PutResult.FULL
        }
        write(id, JSONObject().put("id", id).put("body", body).put("receivedAt", now).put("generation", generation))
        // shortcut: keep 200 fingerprints for 15 minutes; enlarge after measured carrier retry bursts.
        if (seen.length() >= 200) seen.keys().asSequence().minByOrNull { seen.optLong(it) }?.let { seen.remove(it) }
        seen.put(id, now)
        check(prefs.edit().putString("seen", seen.toString()).commit())
        PutResult.ADDED
    }
    fun complete(id: String, expected: Long, payload: JSONObject): Boolean = synchronized(lock) {
        if (!SmsPolicy.canCommit(expected, generation, enabled)) return@synchronized false
        val value = read(id) ?: return@synchronized false
        if (payload.optString("risk") == "low") { remove(id); return@synchronized true }
        if (payload.has("result")) value.put("result", payload.getJSONObject("result"))
        else value.put("error", payload.optString("error", "scanFailed"))
        write(id, value)
        true
    }
    fun reviews(): List<String> = synchronized(lock) {
        ids().mapNotNull { id -> read(id)?.let { id to it.getLong("receivedAt") } }
            .sortedByDescending { it.second }.map { it.first }
    }
}

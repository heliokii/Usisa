package com.example.usisa

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build

object SmsAlerts {
    private const val CHANNEL = "usisa_sms_review"
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)
    fun allowed(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
        val manager = manager(context)
        if (!manager.areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < 26 || manager.getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE
    }
    /** A warning names the verdict ([title]) and sender ([from]); the [body] is left out of the lock-screen version. */
    fun show(context: Context, id: String, failed: Boolean = false, title: String = "", from: String = "", body: String = "") {
        if (!allowed(context)) return
        val store = PendingSmsStore(context)
        val fil = store.language == "fil"
        val fallback = if (failed) {
            if (fil) "May SMS na hindi nasuri. Buksan ang Usisa." else "Some SMS checks could not finish. Open Usisa."
        } else if (fil) "May mensaheng dapat suriin." else "A message needs your review."
        val manager = manager(context)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL,
            if (fil) "Pagsusuri ng SMS" else "SMS reviews", NotificationManager.IMPORTANCE_DEFAULT))
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            data = Uri.parse("usisa-review:$id")
            putExtra("usisa_event_id", id)
        }
        val pending = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context)
        val warning = !failed && title.isNotBlank()
        val heading = if (warning) title else "Usisa"
        val line = if (warning) from else fallback
        val public = builder.setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle(heading).setContentText(line).build()
        val notification = (if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context))
            .setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle(heading).setContentText(line)
            .apply { if (warning) style = Notification.BigTextStyle().bigText(from + "\n" + body) }
            .setContentIntent(pending).setAutoCancel(true).setVisibility(Notification.VISIBILITY_PRIVATE).setPublicVersion(public).build()
        try { manager.notify(id, 1, notification) } catch (_: SecurityException) { }
    }
}

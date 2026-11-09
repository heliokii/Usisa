package com.example.usisa

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var bridge: SmsBridge? = null
    private var permissionReply: MethodChannel.Result? = null
    private var notificationId: String? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = SmsBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState?.containsKey("usisa.pending_notification") == true) notificationId = savedInstanceState.getString("usisa.pending_notification")
        else capture(intent, false)
    }
    override fun onSaveInstanceState(outState: Bundle) {
        synchronized(this) { outState.putString("usisa.pending_notification", notificationId) }
        super.onSaveInstanceState(outState)
    }
    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); capture(intent, true) }
    private fun capture(intent: Intent?, notify: Boolean) {
        val id = intent?.getStringExtra("usisa_event_id") ?: return
        intent.removeExtra("usisa_event_id")
        if (!id.matches(Regex("[0-9a-f-]{36}"))) return
        synchronized(this) { notificationId = id }
        if (notify) bridge?.notifyOpen(id)
    }
    @Synchronized fun takeNotification(): String? { val id = notificationId; notificationId = null; return id }
    fun requestSmsPermissions(reply: MethodChannel.Result, notificationsOnly: Boolean = false) {
        if (!BuildConfig.SMS_ENABLED) { reply.success(null); return }
        if (permissionReply != null) { reply.error("busy", "Permission request already open", null); return }
        val permissions = mutableListOf<String>()
        if (!notificationsOnly && checkSelfPermission(Manifest.permission.RECEIVE_SMS) != PackageManager.PERMISSION_GRANTED) permissions.add(Manifest.permission.RECEIVE_SMS)
        if (notificationsOnly && Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        if (permissions.isEmpty()) { reply.success(null); return }
        permissionReply = reply
        requestPermissions(permissions.toTypedArray(), 7719)
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 7719) { permissionReply?.success(null); permissionReply = null }
    }
    override fun onDestroy() {
        bridge?.dispose(); permissionReply?.error("interrupted", "Permission request interrupted", null); permissionReply = null
        super.onDestroy()
    }
}

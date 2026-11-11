package com.example.usisa

import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.os.Build
import android.os.SystemClock
import android.provider.MediaStore
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.runner.lifecycle.ActivityLifecycleCallback
import androidx.test.runner.lifecycle.ActivityLifecycleMonitorRegistry
import androidx.test.runner.lifecycle.Stage
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PickerRecoveryTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val automation get() = instrumentation.uiAutomation
    private fun find(node: AccessibilityNodeInfo?, predicate: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo? {
        if (node == null) return null
        if (predicate(node)) return node
        repeat(node.childCount) { find(node.getChild(it), predicate)?.let { found -> return found } }
        return null
    }
    private fun waitNode(predicate: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo {
        repeat(150) {
            find(automation.rootInActiveWindow, predicate)?.let { return it }
            SystemClock.sleep(200)
        }
        throw AssertionError("Expected UI state did not appear")
    }
    private fun click(vararg labels: String) {
        val node = waitNode {
            it.isEnabled && it.isClickable &&
                (it.contentDescription?.toString() in labels || it.text?.toString() in labels)
        }
        assertTrue(node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
    }

    @Test fun selectedImageIsRecoveredAfterActivityRecreationWithoutAutomaticScan() {
        assumeTrue(Build.VERSION.SDK_INT >= 29 && Build.MODEL.contains("sdk_gphone"))
        val context = instrumentation.targetContext
        val color = Color.rgb(60, 230, 90)
        val name = "usisa-recovery-${System.currentTimeMillis()}.png"
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/UsisaTest")
            put(MediaStore.Images.Media.DATE_TAKEN, System.currentTimeMillis())
        }
        val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)!!
        val image = Bitmap.createBitmap(1200, 400, Bitmap.Config.ARGB_8888)
        Canvas(image).apply {
            drawColor(color)
            drawText("GCash: Send your OTP immediately.", 32f, 80f, Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = Color.BLACK; textSize = 48f })
        }
        context.contentResolver.openOutputStream(uri)!!.use { assertTrue(image.compress(Bitmap.CompressFormat.PNG, 100, it)) }
        image.recycle()
        val latestActivity = AtomicReference<MainActivity>()
        var callback: ActivityLifecycleCallback? = null
        try {
            val oldActivity = instrumentation.startActivitySync(Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)) as MainActivity
            latestActivity.set(oldActivity)
            val initial = waitNode { it.contentDescription?.toString() in listOf("Start checking", "Simulang magsuri", "Screenshot") }
            if (initial.contentDescription.toString() != "Screenshot") assertTrue(initial.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            click("Screenshot")
            click("Choose screenshot", "Pumili ng screenshot")
            waitNode { it.contentDescription?.startsWith("Photo taken") == true }
            val destroyed = CountDownLatch(1)
            callback = ActivityLifecycleCallback { activity, stage ->
                if (activity is MainActivity && stage != Stage.DESTROYED) latestActivity.set(activity)
                if (activity === oldActivity && stage == Stage.DESTROYED) destroyed.countDown()
            }
            instrumentation.runOnMainSync {
                ActivityLifecycleMonitorRegistry.getInstance().addLifecycleCallback(callback)
                oldActivity.recreate()
            }
            assertTrue("Activity recreation did not complete", destroyed.await(30, TimeUnit.SECONDS))
            SystemClock.sleep(1500)
            val photo = waitNode { node ->
                if (node.contentDescription?.startsWith("Photo taken") != true) false else {
                    val bounds = Rect().also(node::getBoundsInScreen)
                    val screen = automation.takeScreenshot()
                    if (screen == null) false else {
                        val pixel = screen.getPixel(bounds.centerX(), bounds.centerY())
                        screen.recycle()
                        kotlin.math.abs(Color.green(pixel) - 230) < 15 && kotlin.math.abs(Color.red(pixel) - 60) < 15
                    }
                }
            }
            assertTrue(photo.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            click("Review previous screenshot", "Suriin ang nakaraang screenshot")
            waitNode { it.className == "android.widget.EditText" && it.text?.contains("OTP") == true }
            assertNull(find(automation.rootInActiveWindow) { it.contentDescription == "Scan result" })
            context.contentResolver.openInputStream(uri)!!.use { assertTrue(it.read() >= 0) }
        } finally {
            callback?.let { listener -> instrumentation.runOnMainSync { ActivityLifecycleMonitorRegistry.getInstance().removeLifecycleCallback(listener) } }
            instrumentation.runOnMainSync { latestActivity.get()?.finish() }
            context.contentResolver.delete(uri, null, null)
        }
    }
}

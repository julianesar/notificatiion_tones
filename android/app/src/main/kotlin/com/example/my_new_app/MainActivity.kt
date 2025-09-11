package com.example.my_new_app

import android.app.Activity
import android.content.Intent
import android.content.ContentValues
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.notifications_sounds/ringtone_config"
    private val SYSTEM_ALERT_WINDOW_REQUEST = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSystemSettingsPermission" -> {
                    result.success(hasSystemSettingsPermission())
                }
                "requestSystemSettingsPermission" -> {
                    requestSystemSettingsPermission()
                    result.success(true)
                }
                "openSystemSettings" -> {
                    openSystemSettings()
                    result.success(null)
                }
                "setRingtone" -> {
                    val filePath = call.argument<String>("filePath")
                    val ringtoneType = call.argument<String>("ringtoneType")
                    val contactId = call.argument<String>("contactId")
                    
                    if (filePath != null && ringtoneType != null) {
                        val success = setRingtone(filePath, ringtoneType, contactId)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "File path and ringtone type are required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasSystemSettingsPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.System.canWrite(this)
        } else {
            true
        }
    }

    private fun requestSystemSettingsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.System.canWrite(this)) {
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    private fun openSystemSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    private fun setRingtone(filePath: String, ringtoneType: String, contactId: String?): Boolean {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                return false
            }

            // Add the audio file to MediaStore
            val uri = addToMediaStore(file) ?: return false

            // Set the ringtone based on type
            return when (ringtoneType) {
                "call" -> setCallRingtone(uri)
                "notification" -> setNotificationRingtone(uri)
                "alarm" -> setAlarmRingtone(uri)
                "contact" -> setContactRingtone(uri, contactId)
                else -> false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun addToMediaStore(file: File): Uri? {
        return try {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
                put(MediaStore.MediaColumns.MIME_TYPE, "audio/*")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Music/Ringtones")
                put(MediaStore.Audio.Media.IS_RINGTONE, true)
                put(MediaStore.Audio.Media.IS_NOTIFICATION, true)
                put(MediaStore.Audio.Media.IS_ALARM, true)
                put(MediaStore.Audio.Media.IS_MUSIC, false)
            }

            val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
            uri?.let {
                contentResolver.openOutputStream(it)?.use { outputStream ->
                    file.inputStream().use { inputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }
            }
            uri
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun setCallRingtone(uri: Uri): Boolean {
        return try {
            RingtoneManager.setActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE, uri)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun setNotificationRingtone(uri: Uri): Boolean {
        return try {
            RingtoneManager.setActualDefaultRingtoneUri(this, RingtoneManager.TYPE_NOTIFICATION, uri)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun setAlarmRingtone(uri: Uri): Boolean {
        return try {
            RingtoneManager.setActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM, uri)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun setContactRingtone(uri: Uri, contactId: String?): Boolean {
        // Contact-specific ringtones require additional implementation
        // This would typically involve updating the contact's custom ringtone
        // For now, we'll just set it as the default ringtone
        return setCallRingtone(uri)
    }
}

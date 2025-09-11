package com.example.my_new_app

import android.app.Activity
import android.content.Intent
import android.content.ContentValues
import android.content.pm.PackageManager
import android.database.Cursor
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.notifications_sounds/ringtone_config"
    private val SYSTEM_ALERT_WINDOW_REQUEST = 100
    private val CONTACTS_PERMISSION_REQUEST = 101
    
    private var contactsPermissionResult: MethodChannel.Result? = null

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
                "hasContactsPermission" -> {
                    result.success(hasContactsPermission())
                }
                "requestContactsPermission" -> {
                    if (hasContactsPermission()) {
                        result.success(true)
                    } else {
                        contactsPermissionResult = result
                        requestContactsPermission()
                    }
                }
                "getContacts" -> {
                    if (hasContactsPermission()) {
                        val contacts = getContacts()
                        result.success(contacts)
                    } else {
                        result.error("PERMISSION_DENIED", "Contacts permission not granted", null)
                    }
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

    private fun hasContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED &&
               ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_CONTACTS) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestContactsPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                android.Manifest.permission.READ_CONTACTS,
                android.Manifest.permission.WRITE_CONTACTS
            ),
            CONTACTS_PERMISSION_REQUEST
        )
    }

    private fun getContacts(): List<Map<String, String>> {
        val contacts = mutableListOf<Map<String, String>>()
        val cursor: Cursor? = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER
            ),
            null,
            null,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC"
        )

        cursor?.use { c ->
            val idColumn = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
            val nameColumn = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val phoneColumn = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

            while (c.moveToNext()) {
                val id = c.getString(idColumn)
                val name = c.getString(nameColumn)
                val phone = c.getString(phoneColumn)

                if (id != null && name != null) {
                    val contact = mapOf(
                        "id" to id,
                        "name" to name,
                        "phone" to (phone ?: "")
                    )
                    // Avoid duplicates based on contact ID
                    if (!contacts.any { it["id"] == id }) {
                        contacts.add(contact)
                    }
                }
            }
        }

        return contacts
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
        return try {
            if (contactId == null) {
                // If no contact ID provided, set as default ringtone
                return setCallRingtone(uri)
            }

            // Set custom ringtone for specific contact
            val values = ContentValues()
            values.put(ContactsContract.Contacts.CUSTOM_RINGTONE, uri.toString())

            val rowsUpdated = contentResolver.update(
                ContactsContract.Contacts.CONTENT_URI,
                values,
                "${ContactsContract.Contacts._ID} = ?",
                arrayOf(contactId)
            )

            rowsUpdated > 0
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            CONTACTS_PERMISSION_REQUEST -> {
                val contactsPermissionGranted = grantResults.isNotEmpty() && 
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                
                contactsPermissionResult?.success(contactsPermissionGranted)
                contactsPermissionResult = null
            }
        }
    }
}

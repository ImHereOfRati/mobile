package com.kdongsu5509.iamhere

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.ContactsContract
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val contactsChannelName = "com.iamhere.app/contacts"
    private val contactsPermissionRequest = 41
    private var pendingContactsResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            contactsChannelName,
        ).setMethodCallHandler { call, result ->
            if (call.method != "getDeviceContacts") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.READ_CONTACTS,
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                result.success(readContacts())
            } else {
                pendingContactsResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.READ_CONTACTS),
                    contactsPermissionRequest,
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != contactsPermissionRequest) return
        val result = pendingContactsResult ?: return
        pendingContactsResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            result.success(readContacts())
        } else {
            result.error("CONTACTS_PERMISSION_DENIED", "연락처 권한이 필요합니다.", null)
        }
    }

    private fun readContacts(): List<Map<String, Any>> {
        val grouped = linkedMapOf<String, Pair<String, LinkedHashSet<String>>>()
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
        )
        contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            projection,
            null,
            null,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY + " ASC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            )
            val nameIndex = cursor.getColumnIndexOrThrow(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY,
            )
            val numberIndex = cursor.getColumnIndexOrThrow(
                ContactsContract.CommonDataKinds.Phone.NUMBER,
            )
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex).toString()
                val name = cursor.getString(nameIndex).orEmpty()
                val number = cursor.getString(numberIndex)
                    .orEmpty()
                    .replace(Regex("[^0-9+]"), "")
                val entry = grouped.getOrPut(id) { name to linkedSetOf() }
                if (number.isNotEmpty()) entry.second.add(number)
            }
        }
        return grouped.map { (id, contact) ->
            mapOf(
                "id" to id,
                "displayName" to contact.first,
                "phoneNumbers" to contact.second.toList(),
            )
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "high_importance_channel",
            "High Importance Notifications",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "앱의 중요한 알림을 표시하는 채널입니다"
            enableVibration(true)
            enableLights(true)
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        manager.createNotificationChannel(channel)
    }
}

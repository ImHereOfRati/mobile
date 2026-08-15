package com.kdongsu5509.iamhere

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.Intent
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
    private val contactPickerRequest = 42
    private var pendingContactsResult: MethodChannel.Result? = null
    private var pendingPickerResult: MethodChannel.Result? = null

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
            if (call.method != "getDeviceContacts" && call.method != "pickDeviceContact") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.READ_CONTACTS,
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                if (call.method == "pickDeviceContact") {
                    pickContact(result)
                } else {
                    result.success(readContacts())
                }
            } else {
                if (call.method == "pickDeviceContact") {
                    pendingPickerResult = result
                } else {
                    pendingContactsResult = result
                }
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
        if (pendingPickerResult != null) {
            val result = pendingPickerResult
            pendingPickerResult = null
            if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
                pickContact(result!!)
            } else {
                result?.error("CONTACTS_PERMISSION_DENIED", "연락처 권한이 필요합니다.", null)
            }
            return
        }
        val result = pendingContactsResult ?: return
        pendingContactsResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            result.success(readContacts())
        } else {
            result.error("CONTACTS_PERMISSION_DENIED", "연락처 권한이 필요합니다.", null)
        }
    }

    private fun pickContact(result: MethodChannel.Result) {
        pendingPickerResult = result
        startActivityForResult(
            Intent(
                Intent.ACTION_PICK,
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            ),
            contactPickerRequest,
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != contactPickerRequest) return
        val result = pendingPickerResult ?: return
        pendingPickerResult = null
        if (resultCode != RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }
        val uri = data.data!!
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
        )
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) {
                result.success(null)
                return
            }
            val id = cursor.getString(cursor.getColumnIndexOrThrow(
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ))
            val name = cursor.getString(cursor.getColumnIndexOrThrow(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY,
            )).orEmpty()
            val number = cursor.getString(cursor.getColumnIndexOrThrow(
                ContactsContract.CommonDataKinds.Phone.NUMBER,
            )).orEmpty().replace(Regex("[^0-9+]"), "")
            result.success(
                mapOf(
                    "id" to id,
                    "displayName" to name,
                    "phoneNumbers" to listOf(number),
                ),
            )
        } ?: result.success(null)
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

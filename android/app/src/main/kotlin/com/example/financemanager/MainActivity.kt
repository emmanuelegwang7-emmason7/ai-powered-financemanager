package com.example.financemanager

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.telephony.TelephonyManager.UssdResponseCallback
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Channel name must match exactly what Dart uses
    private val CHANNEL = "com.smartfinance.ussd/balance"

    // Permission request code
    private val CALL_PHONE_REQUEST = 101

    // We hold a reference to the pending result so we can reply after the
    // USSD callback fires (which is async)
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // ── Check if CALL_PHONE permission is granted ─────────────
                "checkPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this, Manifest.permission.CALL_PHONE
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }

                // ── Request CALL_PHONE permission ─────────────────────────
                "requestPermission" -> {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.CALL_PHONE),
                        CALL_PHONE_REQUEST
                    )
                    // Result is sent back via onRequestPermissionsResult
                    // We store the result reference to reply there
                    pendingResult = result
                }

                // ── Send USSD and return the response string ──────────────
                "sendUssd" -> {
                    val ussdCode = call.argument<String>("ussdCode")
                        ?: return@setMethodCallHandler result.error(
                            "INVALID_ARG", "ussdCode is required", null
                        )

                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.error(
                            "UNSUPPORTED",
                            "USSD API requires Android 8.0 (API 26) or higher",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val hasPermission = ContextCompat.checkSelfPermission(
                        this, Manifest.permission.CALL_PHONE
                    ) == PackageManager.PERMISSION_GRANTED

                    if (!hasPermission) {
                        result.error(
                            "PERMISSION_DENIED",
                            "CALL_PHONE permission is required",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    sendUssdCode(ussdCode, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ── USSD sender (API 26+) ─────────────────────────────────────────────
    @RequiresApi(Build.VERSION_CODES.O)
    private fun sendUssdCode(ussdCode: String, result: MethodChannel.Result) {
        val telephonyManager =
            getSystemService(TELEPHONY_SERVICE) as TelephonyManager

        telephonyManager.sendUssdRequest(
            ussdCode,
            object : UssdResponseCallback() {
                override fun onReceiveUssdResponse(
                    telephonyManager: TelephonyManager,
                    request: String,
                    response: CharSequence
                ) {
                    // Post back to main thread for Flutter
                    Handler(Looper.getMainLooper()).post {
                        result.success(response.toString())
                    }
                }

                override fun onReceiveUssdResponseFailed(
                    telephonyManager: TelephonyManager,
                    request: String,
                    failureCode: Int
                ) {
                    Handler(Looper.getMainLooper()).post {
                        result.error(
                            "USSD_FAILED",
                            "USSD request failed with code: $failureCode",
                            null
                        )
                    }
                }
            },
            Handler(Looper.getMainLooper())
        )
    }

    // ── Handle permission request result ─────────────────────────────────
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CALL_PHONE_REQUEST) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}

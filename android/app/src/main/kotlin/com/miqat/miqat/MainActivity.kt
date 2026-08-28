package com.miqat.miqat

import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Pont natif vers le sélecteur de sonnerie Android (RingtoneManager), qui
 * permet à la fois de choisir un son prédéfini du système et d'importer un
 * fichier audio depuis le stockage de l'appareil.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "miqat/ringtone_picker"
    private val pickRequestCode = 4242
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickNotificationSound" -> {
                        pendingResult = result
                        val currentUri = call.argument<String>("currentUri")
                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Choisir un son de notification")
                            if (currentUri != null) {
                                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(currentUri))
                            }
                        }
                        startActivityForResult(intent, pickRequestCode)
                    }
                    "getRingtoneTitle" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString == null) {
                            result.success(null)
                        } else {
                            try {
                                val ringtone = RingtoneManager.getRingtone(applicationContext, Uri.parse(uriString))
                                result.success(ringtone?.getTitle(applicationContext))
                            } catch (e: Exception) {
                                result.success(null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == pickRequestCode) {
            val uri: Uri? = data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
            pendingResult?.success(uri?.toString())
            pendingResult = null
        }
    }
}

package app.noteshub.mobile

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.noteshub.mobile/device_download"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePdfToDownloads" -> {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName") ?: "document.pdf"

                    if (filePath.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENTS", "filePath must not be null or empty", null)
                        return@setMethodCallHandler
                    }

                    val sourceFile = File(filePath)
                    if (!sourceFile.exists() || sourceFile.length() <= 0L) {
                        result.error("FILE_NOT_FOUND", "Source file does not exist or is empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedLocation = saveFileToPublicDownloads(this, sourceFile, fileName)
                        result.success(savedLocation)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage ?: "Failed to save file to Downloads", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveFileToPublicDownloads(context: Context, sourceFile: File, fileName: String): String {
        val mimeType = "application/pdf"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = context.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri: Uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw IllegalStateException("Failed to create MediaStore entry in Downloads")

            try {
                resolver.openOutputStream(uri)?.use { outputStream ->
                    FileInputStream(sourceFile).use { inputStream ->
                        inputStream.copyTo(outputStream)
                    }
                    outputStream.flush()
                } ?: throw IllegalStateException("Failed to open output stream for MediaStore URI")

                contentValues.clear()
                contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)

                return "Downloads/$fileName"
            } catch (t: Throwable) {
                resolver.delete(uri, null, null)
                throw t
            }
        } else {
            // Android 9 (Pie, API 28) and lower: Save directly to public Downloads directory
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }

            // Ensure unique filename if destination exists
            var targetFile = File(downloadsDir, fileName)
            var counter = 1
            val dotIndex = fileName.lastIndexOf('.')
            val baseName = if (dotIndex != -1) fileName.substring(0, dotIndex) else fileName
            val extension = if (dotIndex != -1) fileName.substring(dotIndex) else ".pdf"

            while (targetFile.exists()) {
                targetFile = File(downloadsDir, "$baseName ($counter)$extension")
                counter++
            }

            FileInputStream(sourceFile).use { input ->
                FileOutputStream(targetFile).use { output ->
                    input.copyTo(output)
                    output.flush()
                }
            }

            // Tell MediaScanner to index the new file so it appears immediately in Downloads/Files app
            MediaScannerConnection.scanFile(
                context,
                arrayOf(targetFile.absolutePath),
                arrayOf(mimeType),
                null
            )

            return "Downloads/${targetFile.name}"
        }
    }
}


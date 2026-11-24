package kz.mihrab.mihrab

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException

/**
 * Read-only access to the two explicitly selected notification recordings.
 * No arbitrary paths, listing, mutation or access to other app files.
 * Android's notification service needs to resolve the URI after app exit.
 */
class AdhanSoundProvider : ContentProvider() {
    override fun onCreate() = true

    private fun resolve(uri: Uri): File {
        val ctx = context ?: throw FileNotFoundException()
        val profile = uri.pathSegments.singleOrNull()
        if (profile != "standard" && profile != "fajr") throw FileNotFoundException()
        if (uri.authority != "${ctx.packageName}.adhan") throw FileNotFoundException()
        val root = ctx.filesDir
        val file = File(root, "adhan_$profile.audio")
        if (!file.isFile || file.canonicalFile.parentFile != root.canonicalFile ||
            file.length() !in 1L..15728640L) throw FileNotFoundException()
        return file
    }

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw FileNotFoundException("Read only")
        return ParcelFileDescriptor.open(resolve(uri), ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String = "audio/*"

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?,
        selectionArgs: Array<out String>?, sortOrder: String?): Cursor {
        val file = resolve(uri)
        val columns = projection ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        return MatrixCursor(columns).apply {
            val row = Array<Any?>(columns.size) { index ->
                when (columns[index]) {
                    OpenableColumns.DISPLAY_NAME -> file.name
                    OpenableColumns.SIZE -> file.length()
                    else -> null
                }
            }
            addRow(row)
        }
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = throw UnsupportedOperationException()
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int =
        throw UnsupportedOperationException()
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int =
        throw UnsupportedOperationException()
}

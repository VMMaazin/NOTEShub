/// Helper utilities for safe file naming, size formatting, and format validation.
class FileUtils {
  /// Sanitizes a user/document filename for safe local disk storage.
  /// Removes filesystem-illegal characters (\, /, :, *, ?, ", <, >, |) and collapses spaces.
  static String sanitizeFileName(String input, {String defaultName = 'document.pdf'}) {
    var cleaned = input.trim();
    if (cleaned.isEmpty) return defaultName;

    // Replace illegal characters with underscore and strip path traversal patterns
    cleaned = cleaned.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    cleaned = cleaned.replaceAll(RegExp(r'^\.+'), '');

    // Collapse multiple underscores or spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'_+'), '_');

    // Ensure it ends with .pdf
    if (!cleaned.toLowerCase().endsWith('.pdf')) {
      cleaned = '$cleaned.pdf';
    }

    return cleaned;
  }

  /// Formats byte count to human-readable string (e.g. "2.4 MB", "850 KB").
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Verifies whether the provided byte header matches standard PDF magic numbers (`%PDF-`).
  static bool hasPdfSignature(List<int> bytes) {
    if (bytes.length < 4) return false;
    // "%PDF" in ASCII is 0x25, 0x50, 0x44, 0x46
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  /// Reads up to [length] initial bytes from a local file to check file signatures.
  static Future<List<int>> readFileHeader(dynamic file, {int length = 4}) async {
    try {
      if (file == null) return [];
      final raf = file.openSync();
      final bytes = raf.readSync(length) as List<int>;
      raf.closeSync();
      return bytes;
    } catch (_) {
      return [];
    }
  }
}

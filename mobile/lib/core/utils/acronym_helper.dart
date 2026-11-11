/// Ported acronym generator matching Next.js HomeSearch.tsx with enhanced clean character support.
/// Example: "Web Technology" -> "wt", "Operating Systems" -> "os"
class AcronymHelper {
  static String generate(String name) {
    if (name.trim().isEmpty) return '';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          final clean = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          return clean.isNotEmpty ? clean[0] : '';
        })
        .where((c) => c.isNotEmpty)
        .join('')
        .toLowerCase();
  }

  /// Tokenizes a query string into lowercase terms.
  static List<String> tokenize(String query) {
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }
}

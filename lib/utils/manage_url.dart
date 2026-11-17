/// Turns user input into a link that is safe to open, or null if invalid.
/// Bare domains get `https://`; only http(s) links with a host are accepted.
String? normalizeManageUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty || trimmed.contains(' ')) return null;
  final hasScheme = RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(trimmed);
  final candidate = hasScheme ? trimmed : 'https://$trimmed';
  return safeManageUri(candidate) == null ? null : candidate;
}

/// Parses a stored link for opening. Rejects anything but http(s) with a
/// host, since imported backups can carry arbitrary schemes.
Uri? safeManageUri(String? url) {
  if (url == null) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty || !uri.host.contains('.')) return null;
  return uri;
}

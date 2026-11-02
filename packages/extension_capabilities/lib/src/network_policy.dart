import 'dart:io' show InternetAddress;

/// Decides whether an extension may request a URL.
abstract interface class NetworkPolicy {
  /// Throws if [uri] must not be requested.
  void check(Uri uri);
}

/// Allows https requests to an explicit list of domains.
class DomainPolicy implements NetworkPolicy {
  DomainPolicy(Iterable<String> domains)
    : _patterns = domains.map((d) => d.trim().toLowerCase()).toList();

  final List<String> _patterns;

  @override
  void check(Uri uri) {
    if (uri.scheme != 'https') {
      throw ArgumentError('Only https is allowed: $uri');
    }

    final host = uri.host.toLowerCase();
    if (host.isEmpty) {
      throw ArgumentError('URL has no host: $uri');
    }
    if (InternetAddress.tryParse(host) != null) {
      throw ArgumentError('IP addresses are not allowed: $uri');
    }

    if (!_patterns.any((pattern) => _matches(pattern, host))) {
      throw StateError('Domain not allowed: $host');
    }
  }

  static bool _matches(String pattern, String host) {
    if (pattern.startsWith('*.')) {
      // Keep the dot: "*.example.com" -> ".example.com", so "evilexample.com"
      // and "example.com" itself don't match.
      return host.endsWith(pattern.substring(1));
    }
    return host == pattern;
  }
}

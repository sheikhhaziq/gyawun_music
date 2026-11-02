import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'capability.dart';
import 'network_policy.dart';

class NetworkCapability implements Capability {
  NetworkCapability({
    required this.policy,
    required this._client,
    this.timeout = const Duration(seconds: 30),
    this.maxResponseBytes = 5 << 20,
    this.maxRedirects = 5,
  });

  /// Statuses that carry a `Location` to follow. 304 is excluded on purpose.
  static const _redirectStatuses = {301, 302, 303, 307, 308};

  final NetworkPolicy policy;
  final http.Client _client;
  final Duration timeout;
  final int maxResponseBytes;
  final int maxRedirects;

  @override
  String get name => 'network';

  @override
  Future<Object?> handle(String method, Map<String, dynamic> args) {
    if (method != 'fetch') {
      throw ArgumentError('Unknown network method: $method');
    }
    return _fetch(args).timeout(timeout);
  }

  Future<Object?> _fetch(Map<String, dynamic> args) async {
    final url = args['url'];
    if (url is! String) throw ArgumentError('url must be a string');

    var uri = Uri.parse(url);
    var verb = '${args['method'] ?? 'GET'}'.toUpperCase();
    var body = args['body'] as String?;
    final headers = <String, String>{
      for (final e in (args['headers'] as Map? ?? const {}).entries)
        '${e.key}'.toLowerCase(): '${e.value}',
    };

    // Redirects are followed by hand so every hop passes the policy.
    for (var hop = 0; hop <= maxRedirects; hop++) {
      policy.check(uri);

      final request = http.Request(verb, uri)
        ..followRedirects = false
        ..headers.addAll(headers);
      if (body != null) request.body = body;

      final response = await _client.send(request);
      final location = response.headers['location'];

      // Decided from the status code, not response.isRedirect, because that
      // flag is set by the client implementation and can't be trusted.
      if (_redirectStatuses.contains(response.statusCode) && location != null) {
        await response.stream.drain<void>();
        final next = uri.resolve(location);
        if (next.host != uri.host) {
          headers.remove('authorization');
          headers.remove('cookie');
        }
        if (response.statusCode == 303 ||
            ((response.statusCode == 301 || response.statusCode == 302) &&
                verb == 'POST')) {
          verb = 'GET';
          body = null;
        }
        uri = next;
        continue;
      }

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        if (bytes.length > maxResponseBytes) {
          throw StateError('Response exceeds $maxResponseBytes bytes');
        }
      }
      return {
        'status': response.statusCode,
        'headers': response.headers,
        'body': utf8.decode(bytes, allowMalformed: true),
      };
    }
    throw StateError('Too many redirects');
  }
}

import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final policy = DomainPolicy(['api.example.com', '*.cdn.example.com']);

  void allows(String url) =>
      expect(() => policy.check(Uri.parse(url)), returnsNormally, reason: url);

  void rejects(String url, [Matcher? matcher]) => expect(
    () => policy.check(Uri.parse(url)),
    throwsA(matcher ?? anything),
    reason: url,
  );

  group('exact domains', () {
    test('allows a listed host', () {
      allows('https://api.example.com/v1/browse');
    });

    test('allows any path, query and port on a listed host', () {
      allows('https://api.example.com:8443/a/b?x=1#frag');
    });

    test('is case-insensitive', () {
      allows('https://API.Example.COM/');
    });

    test('rejects an unlisted host', () {
      rejects('https://other.com/', isA<StateError>());
    });

    test('rejects a subdomain of an exact entry', () {
      rejects('https://sub.api.example.com/', isA<StateError>());
    });

    test('rejects the parent of an exact entry', () {
      rejects('https://example.com/', isA<StateError>());
    });
  });

  group('wildcard domains', () {
    test('allows a subdomain', () {
      allows('https://img.cdn.example.com/a.png');
    });

    test('allows a nested subdomain', () {
      allows('https://a.b.cdn.example.com/');
    });

    test('rejects the bare domain', () {
      rejects('https://cdn.example.com/', isA<StateError>());
    });

    test('rejects a lookalike without the dot boundary', () {
      rejects('https://evilcdn.example.com/', isA<StateError>());
    });

    test('rejects a lookalike with the domain as a prefix', () {
      rejects('https://img.cdn.example.com.evil.com/', isA<StateError>());
    });
  });

  group('scheme', () {
    test('rejects http', () {
      rejects('http://api.example.com/', isA<ArgumentError>());
    });

    test('rejects other schemes', () {
      rejects('ftp://api.example.com/', isA<ArgumentError>());
      rejects('file:///etc/passwd', isA<ArgumentError>());
      rejects('javascript:alert(1)', isA<ArgumentError>());
    });

    test('rejects a URL with no scheme', () {
      rejects('api.example.com/path', isA<ArgumentError>());
    });
  });

  group('IP addresses', () {
    test('rejects IPv4', () {
      rejects('https://127.0.0.1/', isA<ArgumentError>());
      rejects('https://192.168.1.10/', isA<ArgumentError>());
    });

    test('rejects IPv6', () {
      rejects('https://[::1]/', isA<ArgumentError>());
    });

    test('rejects an IP even if listed', () {
      final listed = DomainPolicy(['127.0.0.1']);

      expect(
        () => listed.check(Uri.parse('https://127.0.0.1/')),
        throwsArgumentError,
      );
    });
  });

  group('host tricks', () {
    test('uses the real host when userinfo looks like an allowed one', () {
      rejects('https://api.example.com@evil.com/', isA<StateError>());
    });

    test('rejects an allowed name used as a path or query', () {
      rejects('https://evil.com/api.example.com', isA<StateError>());
      rejects('https://evil.com/?h=api.example.com', isA<StateError>());
    });

    test('rejects an empty host', () {
      rejects('https:///path', isA<ArgumentError>());
    });
  });

  group('configuration', () {
    test('an empty list allows nothing', () {
      final none = DomainPolicy(const []);

      expect(
        () => none.check(Uri.parse('https://api.example.com/')),
        throwsStateError,
      );
    });

    test('trims and lowercases configured patterns', () {
      final loose = DomainPolicy(['  API.Example.com  ']);

      expect(
        () => loose.check(Uri.parse('https://api.example.com/')),
        returnsNormally,
      );
    });
  });
}

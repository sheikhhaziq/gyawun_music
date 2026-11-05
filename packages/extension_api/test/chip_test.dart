import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

Chip parse(Object? v) => Chip.parse(JsonObject.of(v, 'c'));

void main() {
  test('parses text and keeps the endpoint', () {
    final c = parse({
      'text': 'Recent',
      'endpoint': {'screen': 'recent'},
    });

    expect(c.text, 'Recent');
    expect(c.endpoint.toJson(), {'screen': 'recent'});
  });

  test('rejects a missing or blank text', () {
    expect(() => parse({'endpoint': 1}), throwsFormatException);
    expect(() => parse({'text': ' ', 'endpoint': 1}), throwsFormatException);
  });

  test('rejects a missing or null endpoint', () {
    expect(() => parse({'text': 'x'}), throwsFormatException);
    expect(() => parse({'text': 'x', 'endpoint': null}), throwsFormatException);
  });

  test('the error names the path', () {
    expect(
      () => parse({'text': 'x'}),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('c.endpoint'),
        ),
      ),
    );
  });
}

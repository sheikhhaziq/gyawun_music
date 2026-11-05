import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

SectionAction parse(Object? v) => SectionAction.parse(JsonObject.of(v, 'a'));

void main() {
  group('SectionStyle', () {
    test('parses every style', () {
      for (final s in SectionStyle.values) {
        expect(SectionStyle.parse(s.name), s);
      }
    });

    test('null and unknown fall back to horizontal', () {
      expect(SectionStyle.parse(null), SectionStyle.horizontal);
      expect(SectionStyle.parse('grid'), SectionStyle.horizontal);
      expect(SectionStyle.parse('Vertical'), SectionStyle.horizontal);
    });
  });

  group('SectionAction', () {
    test('parses play and keeps the endpoint', () {
      final a = parse({
        'type': 'play',
        'endpoint': {'id': 1},
      });

      expect(a, isA<PlayAction>());
      expect((a as PlayAction).endpoint.toJson(), {'id': 1});
    });

    test('parses browse and keeps the endpoint', () {
      final a = parse({'type': 'browse', 'endpoint': 'tok'});

      expect((a as BrowseAction).endpoint.toJson(), 'tok');
    });

    test('rejects an unknown or missing type', () {
      expect(
        () => parse({'type': 'playAll', 'endpoint': 1}),
        throwsFormatException,
      );
      expect(() => parse({'endpoint': 1}), throwsFormatException);
    });

    test('rejects a missing or null endpoint', () {
      expect(() => parse({'type': 'play'}), throwsFormatException);
      expect(
        () => parse({'type': 'browse', 'endpoint': null}),
        throwsFormatException,
      );
    });

    test('the error names the path', () {
      expect(
        () => parse({'type': 'play'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('a.endpoint'),
          ),
        ),
      );
    });

    test('parseOptional is null when absent', () {
      expect(
        SectionAction.parseOptional(JsonObject.of({}, 'p'), 'action'),
        isNull,
      );
    });
  });
}

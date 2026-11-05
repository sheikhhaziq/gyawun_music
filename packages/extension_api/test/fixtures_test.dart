import 'dart:convert';
import 'dart:io';

import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

Object? fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

void main() {
  group('hello extension output', () {
    test('home screen parses', () {
      final r = BrowseResult.parse(fixture('home.json'));

      expect(r.header!.title, 'Hello Extension');
      expect(r.chips, hasLength(2));
      expect(r.sections, hasLength(2));
      expect(r.sections.first.style, SectionStyle.horizontal);
      expect(r.sections.first.action, isA<PlayAction>());
      expect(r.sections.last.action, isA<BrowseAction>());
      expect(r.sections.first.items, hasLength(6));
      expect(r.continuation, isNotNull);
    });

    test('items carry artists and endpoints', () {
      final item = BrowseResult.parse(fixture('home.json'))
          .sections
          .first
          .items
          .first;

      expect(item.kind, ItemKind.song);
      expect(item.artists.single.browse, isNotNull);
      expect(item.play, isNotNull);
      expect(item.radio, isNotNull);
      expect(item.thumbnails!.largest.scheme, 'https');
    });

    test('continuation page parses and has no further continuation', () {
      final r = BrowseResult.parse(fixture('continuation.json'));

      expect(r.sections, hasLength(1));
      expect(r.continuation, isNull);
    });

    test('a continuation endpoint round-trips unchanged', () {
      final r = BrowseResult.parse(fixture('home.json'));

      expect(r.continuation!.toJson(), {'page': 2});
    });
  });
}

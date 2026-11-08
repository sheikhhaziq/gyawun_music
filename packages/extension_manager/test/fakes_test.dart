import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'installed_record_test.dart' as helper show record;

void main() {
  test('store saves, replaces and deletes', () async {
    final store = InMemoryStore();
    final r = helper.record();

    await store.save(r);
    await store.save(r.copyWith(enabled: true));

    expect((await store.all()).single.enabled, isTrue);

    await store.delete(r.id);
    await store.delete(r.id); // unknown id is fine

    expect(await store.all(), isEmpty);
  });

  test('files read, write and delete', () async {
    final files = InMemoryFiles();

    expect(await files.read('a'), isNull);

    await files.write('a', Uint8List.fromList([1, 2]));
    expect(await files.read('a'), [1, 2]);

    await files.delete('a');
    expect(await files.read('a'), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'rig.dart';

void main() {
  test('removes the record and the archive', () async {
    final rig = Rig();
    await rig.install(gmx());

    await rig.manager.uninstall('com.example.music');

    expect(await rig.store.all(), isEmpty);
    expect(await rig.files.read('com.example.music'), isNull);
  });

  test('keeps the extension data by default', () async {
    final rig = Rig();
    await rig.install(gmx());

    await rig.manager.uninstall('com.example.music');

    expect(rig.cleared, isEmpty);
  });

  test('clears the data when asked', () async {
    final rig = Rig();
    await rig.install(gmx());

    await rig.manager.uninstall('com.example.music', deleteData: true);

    expect(rig.cleared, ['com.example.music']);
  });

  test('an unknown id is not an error', () async {
    final rig = Rig();

    await expectLater(rig.manager.uninstall('com.nope.none'), completes);
  });

  test('leaves other extensions alone', () async {
    final rig = Rig();
    await rig.install(gmx());
    await rig.install(gmx(id: 'com.other.ext'), id: 'com.other.ext');

    await rig.manager.uninstall('com.example.music');

    expect((await rig.store.all()).single.id, 'com.other.ext');
    expect(await rig.files.read('com.other.ext'), isNotNull);
  });

  test('can be installed again afterwards', () async {
    final rig = Rig();
    await rig.install(gmx());
    await rig.manager.uninstall('com.example.music');

    expect(await rig.install(gmx()), isNotNull);
  });
}

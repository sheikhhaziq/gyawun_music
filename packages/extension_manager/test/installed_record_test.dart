import 'package:extension_manager/extension_manager.dart';
import 'package:flutter_test/flutter_test.dart';

InstalledRecord record() => InstalledRecord(
  id: 'com.a.one',
  version: '1.0.0',
  repositoryUrl: Uri.parse('https://r.example.com/index.json'),
  installedAt: DateTime.utc(2025, 1, 1),
);

void main() {
  test('is disabled by default', () {
    expect(record().enabled, isFalse);
  });

  test('copyWith changes only what is given', () {
    final r = record().copyWith(enabled: true, version: '1.1.0');

    expect(r.enabled, isTrue);
    expect(r.version, '1.1.0');
    expect(r.id, 'com.a.one');
    expect(r.repositoryUrl, record().repositoryUrl);
    expect(r.installedAt, record().installedAt);
  });

  test('the id cannot be changed by copyWith', () {
    expect(record().copyWith().id, 'com.a.one');
  });

  test('equal records are equal and share a hash code', () {
    expect(record(), record());
    expect(record().hashCode, record().hashCode);
    expect(record(), isNot(record().copyWith(enabled: true)));
  });
}

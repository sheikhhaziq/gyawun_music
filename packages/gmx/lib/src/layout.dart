/// File names inside a .gmx archive. Fixed by convention, not configurable.
abstract final class GmxFiles {
  static const metadata = 'metadata.json';
  static const entry = 'extension.js';
  static const icon = 'icon.png';
  static const readme = 'README.md';
  static const changelog = 'CHANGELOG.md';
  static const license = 'LICENSE';

  static const required = {metadata, entry};
  static const optional = {icon, readme, changelog, license};
  static const allowed = {...required, ...optional};
}

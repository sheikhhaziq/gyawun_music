import 'dart:convert';
import 'dart:io';

/// Builds quickjs_engine's native library and links it into every package
/// that depends on it, where the engine's test loader looks
/// (`native/build/` relative to the package running `flutter test`).
///
/// Run from the repo root after `melos bootstrap`.
const _engine = 'quickjs_engine';

/// Directories that contain workspace packages.
const _packageRoots = ['packages', 'apps'];

Never _fail(String message) {
  stderr.writeln('setup_quickjs: $message');
  exit(1);
}

Future<void> main() async {
  final root = Directory.current;
  final engineDir = _resolveEngineDir(root);

  await _build(engineDir);

  final libName = Platform.isMacOS
      ? 'libquickjs_c_bridge_plugin.dylib'
      : 'libquickjs_c_bridge_plugin.so';
  final buildDir = Directory('${engineDir.path}/native/build');
  if (!File('${buildDir.path}/$libName').existsSync()) {
    _fail('Build finished but $libName is missing in ${buildDir.path}.');
  }

  final consumers = _findConsumers(root);
  if (consumers.isEmpty) {
    stdout.writeln('setup_quickjs: no packages depend on $_engine.');
    return;
  }
  for (final package in consumers) {
    _link(package, buildDir);
  }
}

/// Locates the resolved quickjs_engine package via package_config.json.
Directory _resolveEngineDir(Directory root) {
  final config = File('${root.path}/.dart_tool/package_config.json');
  if (!config.existsSync()) {
    _fail('.dart_tool/package_config.json not found. Run `melos bootstrap`.');
  }
  final packages = (jsonDecode(config.readAsStringSync())['packages'] as List)
      .cast<Map<String, dynamic>>();
  final entry = packages.firstWhere(
    (p) => p['name'] == _engine,
    orElse: () => _fail('$_engine is not in package_config.json.'),
  );
  // rootUri may be relative to the config file.
  return Directory.fromUri(config.uri.resolve(entry['rootUri'] as String));
}

Future<void> _build(Directory engineDir) async {
  final script = File('${engineDir.path}/tool/build_native.sh');
  if (!script.existsSync()) _fail('Missing ${script.path}.');
  final process = await Process.start(
    'sh',
    ['tool/build_native.sh'],
    workingDirectory: engineDir.path,
    mode: ProcessStartMode.inheritStdio,
  );
  if (await process.exitCode != 0) _fail('Native build failed.');
}

/// Packages under [_packageRoots] whose pubspec mentions quickjs_engine
/// and which have a test directory.
List<Directory> _findConsumers(Directory root) {
  final result = <Directory>[];
  for (final name in _packageRoots) {
    final parent = Directory('${root.path}/$name');
    if (!parent.existsSync()) continue;
    for (final entity in parent.listSync().whereType<Directory>()) {
      final pubspec = File('${entity.path}/pubspec.yaml');
      if (!pubspec.existsSync()) continue;
      final dependsOnEngine = RegExp(
        '^\\s*$_engine\\s*:',
        multiLine: true,
      ).hasMatch(pubspec.readAsStringSync());
      if (dependsOnEngine && Directory('${entity.path}/test').existsSync()) {
        result.add(entity);
      }
    }
  }
  return result;
}

void _link(Directory package, Directory buildDir) {
  final link = Link('${package.path}/native/build');
  link.parent.createSync(recursive: true);
  if (link.existsSync()) link.deleteSync();
  link.createSync(buildDir.path);
  stdout.writeln('Linked ${link.path} -> ${buildDir.path}');
}

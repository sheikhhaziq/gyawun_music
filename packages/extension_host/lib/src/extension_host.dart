import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:gmx/gmx.dart';
import 'package:http/http.dart' as http;
import 'package:js_bridge/js_bridge.dart';
import 'package:quickjs_engine/quickjs_engine.dart';

/// Creates the storage backend for one extension. Called once per start.
typedef StorageFactory = ExtensionStorage Function(String extensionId);

/// Each host owns its own JS runtime, so a timeout or crash in one extension
/// can't affect another.
class ExtensionHost {
  ExtensionHost._(this.metadata, this._bridge);

  final GmxMetadata metadata;
  final JsBridge _bridge;

  static Future<ExtensionHost> start(
    GmxArchive archive, {
    required StorageFactory storageFor,
    required LogSink logSink,
    required http.Client httpClient,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final metadata = archive.metadata;
    final permissions = metadata.permissions;

    final networkTimeout = timeout * 2 ~/ 3;

    final router = CapabilityRouter([
      if (permissions.storage) StorageCapability(storageFor(metadata.id)),
      if (permissions.log)
        LoggingCapability(extensionId: metadata.id, sink: logSink),
      if (permissions.network)
        NetworkCapability(
          policy: DomainPolicy(permissions.networkDomains),
          client: httpClient,
          timeout: networkTimeout,
        ),
    ]);

    final bridge = JsBridge(
      runtime: getJavascriptRuntime(xhr: false),
      onAction: router.handle,
      timeout: timeout,
    );

    try {
      bridge.load(
        buildExtensionScript(archive.script, granted: permissions.granted),
        sourceUrl: '${metadata.id}.js',
      );
    } catch (_) {
      bridge.dispose(); // don't leak a runtime when loading fails
      rethrow;
    }

    return ExtensionHost._(metadata, bridge);
  }

  bool get isDisposed => _bridge.isDisposed;

  Future<Object?> invoke(String method, [List<Object?> args = const []]) =>
      _bridge.call('__extensionCall', arguments: [method, ...args]);

  void dispose() => _bridge.dispose();
}

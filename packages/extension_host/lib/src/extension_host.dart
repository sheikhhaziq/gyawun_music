import 'dart:async';

import 'package:extension_api/extension_api.dart';
import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:gmx/gmx.dart';
import 'package:http/http.dart' as http;
import 'package:js_bridge/js_bridge.dart';
import 'package:quickjs_engine/quickjs_engine.dart';

/// Creates the storage backend for one extension. Called once per start.
typedef StorageFactory = ExtensionStorage Function(String extensionId);

/// Runs one extension from a validated [GmxArchive].
///
/// Each host owns its own JS runtime, so a timeout or crash in one extension
/// can't affect another. All timeouts live here.
class ExtensionHost {
  ExtensionHost._(this.metadata, this._bridge, this._timeout, this.methods);

  final GmxMetadata metadata;
  final JsBridge _bridge;
  final Duration _timeout;

  /// Methods the extension implements. Only the ones its `provides` promises
  /// are guaranteed; the rest (`items`, `queue`, `getStream`) exist only if
  /// the extension emits the matching endpoints.
  final Set<String> methods;

  /// Builds the capabilities the extension asked for (and nothing else),
  /// starts a runtime, loads the script and checks it keeps its `provides`
  /// promises.
  ///
  /// [timeout] bounds each [invoke]. Each capability call made by JS is
  /// bounded by two thirds of it, so JS gets an error it can handle before
  /// the call as a whole times out.
  ///
  /// Throws [StateError] if the script fails to load or a provided capability
  /// has no method.
  static Future<ExtensionHost> start(
    GmxArchive archive, {
    required StorageFactory storageFor,
    required LogSink logSink,
    required http.Client httpClient,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'Must be greater than zero',
      );
    }
    final metadata = archive.metadata;
    final permissions = metadata.permissions;
    final actionTimeout = timeout * 2 ~/ 3;

    final router = CapabilityRouter([
      if (permissions.storage) StorageCapability(storageFor(metadata.id)),
      if (permissions.log)
        LoggingCapability(extensionId: metadata.id, sink: logSink),
      if (permissions.network)
        NetworkCapability(
          policy: DomainPolicy(permissions.networkDomains),
          client: httpClient,
        ),
    ]);

    final bridge = JsBridge(
      runtime: getJavascriptRuntime(xhr: false),
      onAction: (action) => Future.sync(() => router.handle(action)).timeout(
        actionTimeout,
        onTimeout: () => throw TimeoutException(
          'Capability call timed out after ${actionTimeout.inMilliseconds} ms',
          actionTimeout,
        ),
      ),
    );

    try {
      bridge.load(
        buildExtensionScript(archive.script, granted: permissions.granted),
        sourceUrl: '${metadata.id}.js',
      );

      final names = await bridge.call('__extensionMethods').timeout(timeout);
      final methods = Set<String>.unmodifiable((names as List).cast<String>());

      // The only method promised today is browse. Everything else is optional
      // and checked when it is called.
      if (metadata.provides.contains(GmxCapability.browse) &&
          !methods.contains('browse')) {
        throw StateError(
          'Extension ${metadata.id} declares "browse" in provides '
          'but has no browse method',
        );
      }

      return ExtensionHost._(metadata, bridge, timeout, methods);
    } catch (_) {
      bridge.dispose(); // don't leak a runtime when starting fails
      rethrow;
    }
  }

  /// Calls a method the extension returned from its factory function.
  ///
  /// Arguments and the result must be JSON-compatible. Throws [StateError]
  /// if the method doesn't exist, the extension throws, or the host is
  /// disposed. Throws [TimeoutException] if the call exceeds the timeout, and
  /// disposes the host, because a pending JS promise can't be cancelled.
  ///
  /// Calls run one at a time, so time spent waiting behind another call
  /// counts toward the timeout.
  Future<Object?> invoke(String method, [List<Object?> args = const []]) =>
      _bridge
          .call('__extensionCall', arguments: [method, ...args])
          .timeout(
            _timeout,
            onTimeout: () {
              dispose();
              throw TimeoutException(
                'Extension call "$method" timed out after '
                '${_timeout.inMilliseconds} ms',
                _timeout,
              );
            },
          );

  /// Without [endpoint]: the home screen. With one from a chip, a ref, an
  /// item's `browse` or a `continuation`: that screen.
  Future<BrowseResult> browse([Endpoint<BrowseResult>? endpoint]) async {
    _require(GmxCapability.browse, 'browse');
    return _typed('browse', [
      if (endpoint != null) endpoint.toJson(),
    ], BrowseResult.parse);
  }

  /// A flat list of items, for a section's `browse` action or an items
  /// `continuation`. Optional: only extensions that emit such endpoints
  /// implement it.
  Future<ItemsResult> items(Endpoint<ItemsResult> endpoint) async {
    _requireEmitted(GmxCapability.browse, 'items');
    return _typed('items', [endpoint.toJson()], ItemsResult.parse);
  }

  /// Playable items, for a `play` action or an item's play, radio or shuffle
  /// endpoint, or a queue `continuation`. Optional.
  Future<QueueResult> queue(Endpoint<QueueResult> endpoint) async {
    _requireEmitted(GmxCapability.browse, 'queue');
    return _typed('queue', [endpoint.toJson()], QueueResult.parse);
  }

  /// Resolves an item's stream at play time. Optional.
  Future<StreamResult> getStream(Endpoint<StreamResult> endpoint) async {
    _requireEmitted(GmxCapability.browse, 'getStream');
    return _typed('getStream', [endpoint.toJson()], StreamResult.parse);
  }

  /// The extension doesn't provide [capability] at all: a caller mistake.
  void _require(GmxCapability capability, String method) {
    if (!metadata.provides.contains(capability)) {
      throw UnsupportedError(
        'Extension ${metadata.id} does not provide ${capability.name}, '
        'so $method is not available',
      );
    }
  }

  /// An optional method: the extension must implement it if it emitted an
  /// endpoint for it. A missing one is an extension bug.
  void _requireEmitted(GmxCapability capability, String method) {
    _require(capability, method);
    if (!methods.contains(method)) {
      throw StateError(
        'Extension ${metadata.id} does not implement "$method" '
        'but emitted an endpoint for it',
      );
    }
  }

  /// Calls [method] and parses the result. Invalid data becomes a
  /// [FormatException] that names the method and the field.
  Future<T> _typed<T>(
    String method,
    List<Object?> args,
    T Function(Object? value, String path) parse,
  ) async {
    final value = await invoke(method, args);
    try {
      return parse(value, method);
    } on FormatException catch (e) {
      throw FormatException(
        'Extension returned invalid data from $method: ${e.message}',
      );
    }
  }

  bool get isDisposed => _bridge.isDisposed;

  void dispose() => _bridge.dispose();
}

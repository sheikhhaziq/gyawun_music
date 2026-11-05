import 'dart:async';

import 'package:extension_api/extension_api.dart';
import 'package:gmx/gmx.dart';
import 'package:http/http.dart' as http;
import 'package:extension_capabilities/extension_capabilities.dart';

import 'extension_host.dart';

/// Keeps one extension usable across timeouts.
///
/// A timed-out call disposes the underlying [ExtensionHost], because a pending
/// JS promise can't be cancelled. The next call starts a fresh runtime from
/// the same archive. State kept in JS memory is lost on restart; state in
/// storage survives.
class ManagedExtension {
  ManagedExtension(
    this.archive, {
    required this._storageFor,
    required this._logSink,
    required this._httpClient,
    this._timeout = const Duration(seconds: 30),
  });

  final GmxArchive archive;
  final StorageFactory _storageFor;
  final LogSink _logSink;
  final http.Client _httpClient;
  final Duration _timeout;

  ExtensionHost? _host;
  Future<ExtensionHost>? _starting;
  bool _closed = false;
  int _starts = 0;

  GmxMetadata get metadata => archive.metadata;

  /// How many runtimes have been started so far.
  int get starts => _starts;

  bool get isClosed => _closed;

  Future<ExtensionHost> _ready() {
    if (_closed) throw StateError('Extension is closed');
    final host = _host;
    if (host != null && !host.isDisposed) return Future.value(host);
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<ExtensionHost> _start() async {
    final host = await ExtensionHost.start(
      archive,
      storageFor: _storageFor,
      logSink: _logSink,
      httpClient: _httpClient,
      timeout: _timeout,
    );
    if (_closed) {
      host.dispose(); // closed while starting
      throw StateError('Extension is closed');
    }
    _starts++;
    return _host = host;
  }

  Future<T> _run<T>(Future<T> Function(ExtensionHost host) op) async =>
      op(await _ready());

  Future<Object?> invoke(String method, [List<Object?> args = const []]) =>
      _run((h) => h.invoke(method, args));

  Future<BrowseResult> browse([Endpoint<BrowseResult>? endpoint]) =>
      _run((h) => h.browse(endpoint));

  Future<ItemsResult> items(Endpoint<ItemsResult> endpoint) =>
      _run((h) => h.items(endpoint));

  Future<QueueResult> queue(Endpoint<QueueResult> endpoint) =>
      _run((h) => h.queue(endpoint));

  Future<StreamResult> getStream(Endpoint<StreamResult> endpoint) =>
      _run((h) => h.getStream(endpoint));

  /// Stops the extension for good.
  void close() {
    _closed = true;
    _host?.dispose();
    _host = null;
  }
}

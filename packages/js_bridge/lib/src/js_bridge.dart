import 'dart:async';
import 'dart:convert';

import 'package:js_bridge/src/js_scripts.dart';
import 'package:quickjs_engine/extensions/handle_promises.dart';
import 'package:quickjs_engine/javascript_runtime.dart';

/// Handles messages sent from JS. The return value must be JSON-compatible
/// and is sent back to JavaScript.
typedef JsActionHandler = FutureOr<Object?> Function(
  Map<String, dynamic> action,
);

class JsBridge {
  JsBridge({
    required this.runtime,
    required this.onAction,
    this.timeout = const Duration(seconds: 30),
  }) {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'Must be greater than zero',
      );
    }
    runtime.onMessage(_channel, _receiveAction);
    load(jsBridgeScript, sourceUrl: 'js_bridge.js');
  }

  static const _channel = 'extensionAction';

  final JavascriptRuntime runtime;
  final JsActionHandler onAction;

  final Duration timeout;

  final _disposedSignal = Completer<void>();
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  bool get isDisposed => _disposed;

  /// /// Evaluates Extension source. It only runs once.
  void load(String source, {String sourceUrl = 'extension.js'}) {
    _ensureOpen();
    final result = runtime.evaluate(source, sourceUrl: sourceUrl);
    if (result.isError) {
      throw StateError('JavaScript evaluation failed: ${result.stringResult}');
    }
  }

  /// Calls js functions with JSON-compatible
  /// arguments and returns its JSON-compatible result.
  Future<Object?> call(
    String functionName, {
    List<Object?> arguments = const [],
  }) {
    _ensureOpen();
    _checkName(functionName);

    final nameJson = jsonEncode(functionName);
    final argsJson = jsonEncode(arguments);

    return _enqueue(() async {
      final pending = runtime.evaluate('__jsBridgeCall($nameJson, $argsJson)');
      if (pending.isError) {
        throw StateError(
          'JavaScript evaluation failed: ${pending.stringResult}',
        );
      }

      final resolved = await _awaitPromise(pending);
      _ensureOpen();

      if (resolved.isError) {
        throw StateError('JavaScript promise failed: ${resolved.stringResult}');
      }
      return _unwrap(resolved.stringResult as String);
    });
  }

  /// Handles `sendMessage('extensionAction', ...)` from JS. Never throws;
  /// always returns a JSON envelope.
  Future<String> _receiveAction(dynamic raw) async {
    if (_disposed) return _error('JavaScript connection is disposed');
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) {
        throw const FormatException('Action must be a JSON object');
      }
      final action = Map<String, dynamic>.unmodifiable(decoded);
      final value = await onAction(action);
      return jsonEncode({'ok': true, 'value': value}); // throws if not JSON
    } catch (e) {
      return _error(e.toString());
    }
  }

  Future<dynamic> _awaitPromise(dynamic pending) async {
    try {
      return await Future.any<dynamic>([
        runtime.handlePromise(pending),
        _disposedSignal.future.then<dynamic>(
          (_) => throw StateError(
            'JavaScript connection was disposed during a call',
          ),
        ),
      ]).timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'JavaScript call timed out after ${timeout.inMilliseconds} ms',
          timeout,
        ),
      );
    } on TimeoutException {
      dispose();
      rethrow;
    }
  }

  /// Parses the `{ok, value | error, stack}` envelope produced by JS.
  Object? _unwrap(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      throw StateError('Invalid JavaScript bridge JSON: ${e.message}');
    }
    if (decoded is! Map || decoded['ok'] is! bool) {
      throw StateError('Invalid JavaScript response envelope');
    }
    if (decoded['ok'] != true) {
      final message = decoded['error']?.toString() ?? 'JavaScript call failed';
      final stack = decoded['stack']?.toString();
      throw StateError(
        stack == null || stack.isEmpty ? message : '$message\n$stack',
      );
    }
    return decoded['value'];
  }

  /// Runs operations one at a time. A failure doesn't block later operations.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _queue.then<T>((_) {
      _ensureOpen();
      return operation();
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static String _error(String message) =>
      jsonEncode({'ok': false, 'error': message});

  /// Checks if function is valid or not
  static void _checkName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'functionName', 'Must not be empty');
    }
  }

  /// Checks if runtime is disposed
  void _ensureOpen() {
    if (_disposed) throw StateError('JavaScript connection is disposed');
  }

  /// Disposes the runtime.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (!_disposedSignal.isCompleted) _disposedSignal.complete();
    runtime.dispose();
  }
}

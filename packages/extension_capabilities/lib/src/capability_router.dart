import 'dart:async';

import 'capability.dart';

/// Routes `{cap, method, args}` actions from JS to the matching [Capability].
///
/// Pass [handle] as `JsBridge.onAction`.
class CapabilityRouter {
  CapabilityRouter(Iterable<Capability> capabilities)
    : _capabilities = _index(capabilities);

  final Map<String, Capability> _capabilities;

  FutureOr<Object?> handle(Map<String, dynamic> action) {
    final cap = action['cap'];
    final method = action['method'];
    if (cap is! String || method is! String) {
      throw ArgumentError('Action needs string "cap" and "method"');
    }

    final capability = _capabilities[cap];
    if (capability == null) {
      throw StateError('Capability not granted: $cap');
    }

    final args = action['args'];
    return capability.handle(
      method,
      args is Map ? Map<String, dynamic>.from(args) : const {},
    );
  }

  static Map<String, Capability> _index(Iterable<Capability> capabilities) {
    final map = <String, Capability>{};
    for (final capability in capabilities) {
      if (map.containsKey(capability.name)) {
        throw ArgumentError('Duplicate capability: ${capability.name}');
      }
      map[capability.name] = capability;
    }
    return map;
  }
}

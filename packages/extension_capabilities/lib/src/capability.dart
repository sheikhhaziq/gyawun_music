import 'dart:async';

abstract interface class Capability {
  String get name;

  FutureOr<Object?> handle(String method, Map<String, dynamic> args);
}

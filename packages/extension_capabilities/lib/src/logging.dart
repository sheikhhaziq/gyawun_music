import 'capability.dart';

enum LogLevel { debug, info, warn, error }

/// Where log entries end up. Supplied by the app.
typedef LogSink = void Function(
  String extensionId,
  LogLevel level,
  String message,
);

class LoggingCapability implements Capability {
  LoggingCapability({
    required this.extensionId,
    required this.sink,
    this.maxMessageLength = 4000,
  });

  final String extensionId;
  final LogSink sink;
  final int maxMessageLength;

  @override
  String get name => 'logging';

  @override
  Object? handle(String method, Map<String, dynamic> args) {
    if (method != 'write') {
      throw ArgumentError('Unknown logging method: $method');
    }

    final level = LogLevel.values.asNameMap()[args['level']] ?? LogLevel.info;

    var message = '${args['message']}';
    if (message.length > maxMessageLength) {
      message = '${message.substring(0, maxMessageLength)}…';
    }

    sink(extensionId, level, message);
    return null;
  }
}

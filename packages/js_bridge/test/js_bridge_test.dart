import 'package:flutter_test/flutter_test.dart';
import 'package:js_bridge/js_bridge.dart';

import 'helpers.dart';

void main() {
  late JsBridge js;
  setUp(() {
    js = JsBridge(runtime: createRuntime());
  });

  tearDown(() => js.dispose());

  group('call', () {
    test('returns the value of a sync JS function', () async {
      js.load('function add(a, b) { return a + b; }');

      final result = await js.call('add', arguments: [1, 2]);

      expect(result, 3);
    });
  });
}

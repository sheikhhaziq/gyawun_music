import 'dart:convert';
import 'dart:developer';

void pprint(Object? data) {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(data);
  log(jsonString);
}

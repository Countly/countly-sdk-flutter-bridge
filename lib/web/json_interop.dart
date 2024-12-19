// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';

@JS('JSON') // JSON
@staticInterop
class JSON {
  external static String stringify(JSAny? object);
}

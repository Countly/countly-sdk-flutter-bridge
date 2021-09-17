import 'package:js/js_util.dart' as js;

class JsObject {
  final dynamic _object;

  const JsObject(this._object);

  dynamic operator[](String name) => js.getProperty(_object, name);
  operator[]=(String name, dynamic value) => js.setProperty(_object, name, value);
}

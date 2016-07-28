// DO NOT EDIT: auto-generated with `pub run custom_element_apigen:update`

/// Dart API for the polymer element `example_element_with_overrides`.
@HtmlImport('example_element_with_overrides_nodart.html')
library e2e_test.lib.src.example_element_with_overrides.example_element_with_overrides;

import 'dart:html';
import 'dart:js' show JsArray, JsObject;
import 'package:web_components/web_components.dart';
import 'package:polymer_interop/polymer_interop.dart';

/// An example element.
@CustomElementProxy('example-element-with-overrides')
class ExampleElementWithOverrides extends HtmlElement with CustomElementProxyMixin, PolymerBase {
  ExampleElementWithOverrides.created() : super.created();
  factory ExampleElementWithOverrides() => new Element.tag('example-element-with-overrides');

  /// A public Array property.
  List get elementArrayProperty => jsElement[r'elementArrayProperty'];
  set elementArrayProperty(List value) { jsElement[r'elementArrayProperty'] = (value != null && value is! JsArray) ? new JsObject.jsify(value) : value;}

  num get elementNum => jsElement[r'elementNum'];
  set elementNum(num value) { jsElement[r'elementNum'] = value; }

  num get elementNumGetterOnly => jsElement[r'elementNumGetterOnly'];

  set elementNumSetterOnly(num value) { jsElement[r'elementNumSetterOnly'] = value; }

  /// A public property created with the properties descriptor.
  get elementPublicProperty => jsElement[r'elementPublicProperty'];
  set elementPublicProperty(value) { jsElement[r'elementPublicProperty'] = (value is Map || (value is Iterable && value is! JsArray)) ? new JsObject.jsify(value) : value;}

  /// A read only property.
  num get elementReadOnlyProperty => jsElement[r'elementReadOnlyProperty'];
  set elementReadOnlyProperty(num value) { jsElement[r'elementReadOnlyProperty'] = value; }

  /// A property whose type will be overridden
  String get elementWrongTypeProperty => jsElement[r'elementWrongTypeProperty'];
  set elementWrongTypeProperty(String value) { jsElement[r'elementWrongTypeProperty'] = value; }

  /// get the custom object
  get myCustomMapping => toDart(jsElement['myCustomMapping']);
  toDart(x) {
    // Some code that will map x to the proper type
    return x;
  }

  /// set the custom object
  set myCustomMapping(v) => jsElement['myCustomMapping']=toJs(v);
  toJs(x) {
    // Some code that will create the proper js rappresentation of x
    return new JsObject.jsify(x);
  }

  /// This is overridden
  void computedFunction(x,y,z) => jsElement.callMethod('computedFunction',[x,y,z]);

  String elementFunction(String stringParam) =>
      jsElement.callMethod('elementFunction', [stringParam]);

  /// Provide var args
  void elementToBeOverriddenFunction(List varargs) => jsElement.callMethod('elementToBeOverriddenFunction',varargs);

  elementVoidFunction() =>
      jsElement.callMethod('elementVoidFunction', []);

  /// This is actually a property
  get someHandler => jsElement['someHandler'];
  set someHandler(f) => jsElement['someHandler'] = f;
}

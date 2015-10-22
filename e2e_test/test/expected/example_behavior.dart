// DO NOT EDIT: auto-generated with `pub run custom_element_apigen:update`

/// Dart API for the polymer element `example_behavior`.
@HtmlImport('example_behavior_nodart.html')
library e2e_test.lib.src.example_behavior.example_behavior;

import 'dart:html';
import 'dart:js' show JsArray, JsObject;
import 'package:web_components/web_components.dart';
import 'package:polymer_interop/polymer_interop.dart';

/// This is an example behavior!
@BehaviorProxy(const ['Polymer', 'ExampleBehavior'])
abstract class ExampleBehavior implements CustomElementProxyMixin {

  num get behaviorNum => jsElement[r'behaviorNum'];
  set behaviorNum(num value) { jsElement[r'behaviorNum'] = value; }

  num get behaviorNumGetterOnly => jsElement[r'behaviorNumGetterOnly'];

  set behaviorNumSetterOnly(value) { jsElement[r'behaviorNumSetterOnly'] = (value is Map || (value is Iterable && value is! JsArray)) ? new JsObject.jsify(value) : value;}

  /// A public property created with the properties descriptor.
  get behaviorPublicProperty => jsElement[r'behaviorPublicProperty'];
  set behaviorPublicProperty(value) { jsElement[r'behaviorPublicProperty'] = (value is Map || (value is Iterable && value is! JsArray)) ? new JsObject.jsify(value) : value;}

  /// A read only property.
  num get behaviorReadOnlyProperty => jsElement[r'behaviorReadOnlyProperty'];
  set behaviorReadOnlyProperty(num value) { jsElement[r'behaviorReadOnlyProperty'] = value; }

  /// A property whose type will be overridden
  num get behaviorWrongTypeProperty => jsElement[r'behaviorWrongTypeProperty'];
  set behaviorWrongTypeProperty(num value) { jsElement[r'behaviorWrongTypeProperty'] = value; }

  /// [stringParam]: {string}
  String behaviorFunction(stringParam) =>
      jsElement.callMethod('behaviorFunction', [stringParam]);

  behaviorVoidFunction() =>
      jsElement.callMethod('behaviorVoidFunction', []);
}

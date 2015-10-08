// DO NOT EDIT: auto-generated with `pub run custom_element_apigen:update`

/// Dart API for the polymer element `example_multi_behavior`.
@HtmlImport('example_multi_behavior_nodart.html')
library e2e_test.lib.src.example_multi_behavior.example_multi_behavior;

import 'dart:html';
import 'dart:js' show JsArray, JsObject;
import 'package:web_components/web_components.dart';
import 'package:polymer_interop/polymer_interop.dart';
import 'example_behavior.dart';

/// This is an example behavior!
@BehaviorProxy(const ['Polymer', 'ExampleMultiBehavior'])
abstract class ExampleMultiBehavior implements CustomElementProxyMixin, ExampleBehavior {

  /// A public property created with the properties descriptor.
  get anotherPublicProperty => jsElement[r'anotherPublicProperty'];
  set anotherPublicProperty(value) { jsElement[r'anotherPublicProperty'] = (value is Map || (value is Iterable && value is! JsArray)) ? new JsObject.jsify(value) : value;}

  /// [stringParam]: {string}
  String anotherBehaviorFunction(stringParam) =>
      jsElement.callMethod('anotherBehaviorFunction', [stringParam]);
}

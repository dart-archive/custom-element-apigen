// DO NOT EDIT: auto-generated with `pub run custom_element_apigen:update`

/// Dart API for the polymer element `example_multi_deep_behavior`.
@HtmlImport('example_multi_deep_behavior_nodart.html')
library e2e_test.lib.src.example_multi_deep_behavior.example_multi_deep_behavior;

import 'dart:html';
import 'dart:js' show JsArray, JsObject;
import 'package:web_components/web_components.dart';
import 'package:polymer_interop/polymer_interop.dart';
import 'example_multi_behavior.dart';
import 'example_behavior.dart';

/// This is an example behavior!
@BehaviorProxy(const ['Polymer', 'ExampleMultiDeepBehavior'])
abstract class ExampleMultiDeepBehavior implements CustomElementProxyMixin, ExampleMultiBehavior {

  /// A public property created with the properties descriptor.
  get yetAnotherPublicProperty => jsElement[r'yetAnotherPublicProperty'];
  set yetAnotherPublicProperty(value) { jsElement[r'yetAnotherPublicProperty'] = (value is Map || (value is Iterable && value is! JsArray)) ? new JsObject.jsify(value) : value;}
}

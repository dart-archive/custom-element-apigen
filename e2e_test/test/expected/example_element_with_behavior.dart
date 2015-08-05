// DO NOT EDIT: auto-generated with `pub run custom_element_apigen:update`

/// Dart API for the polymer element `example_element_with_behavior`.
@HtmlImport('example_element_with_behavior_nodart.html')
library e2e_test.lib.src.example_element_with_behavior.example_element_with_behavior;

import 'dart:html';
import 'dart:js' show JsArray, JsObject;
import 'package:web_components/web_components.dart';
import 'package:polymer_interop/polymer_interop.dart';
import 'example_behavior.dart';

/// An example element with a behavior.
@CustomElementProxy('example-element-with-behavior')
class ExampleElementWithBehavior extends HtmlElement with CustomElementProxyMixin, PolymerProxyMixin, ExampleBehavior {
  ExampleElementWithBehavior.created() : super.created();
  factory ExampleElementWithBehavior() => new Element.tag('example-element-with-behavior');
}

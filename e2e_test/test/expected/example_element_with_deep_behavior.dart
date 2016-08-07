// DO NOT EDIT: auto-generated with `pub run custom_element_apigen:update`

/// Dart API for the polymer element `example_element_with_deep_behavior`.
@HtmlImport('example_element_with_deep_behavior_nodart.html')
library e2e_test.lib.src.example_element_with_deep_behavior.example_element_with_deep_behavior;

import 'dart:html';
import 'dart:js' show JsArray, JsObject;
import 'package:web_components/web_components.dart';
import 'package:polymer_interop/polymer_interop.dart';
import 'example_multi_deep_behavior.dart';
import 'example_multi_behavior.dart';
import 'example_behavior.dart';

/// An example element with a behavior with deep dependencies.
@CustomElementProxy('example-element-with-deep-behavior')
class ExampleElementWithDeepBehavior extends HtmlElement
    with
        CustomElementProxyMixin,
        PolymerBase,
        ExampleBehavior,
        ExampleMultiBehavior,
        ExampleMultiDeepBehavior {
  ExampleElementWithDeepBehavior.created() : super.created();
  factory ExampleElementWithDeepBehavior() =>
      new Element.tag('example-element-with-deep-behavior');
}

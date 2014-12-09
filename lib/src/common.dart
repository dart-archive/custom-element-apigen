// Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
// This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
// The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
// The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
// Code distributed by Google as part of the polymer project is also
// subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt

/// Common logic used by the code generated with `tool/generate_dart_api.dart`.
library custom_element_apigen.src.common;
import 'dart:html' show Element, DocumentFragment;
import 'dart:js' as js;

/// A simple mixin to make it easier to interoperate with the Javascript API of
/// a browser object. This is mainly used by classes that expose a Dart API for
/// Javascript custom elements.
// TODO(sigmund): move this to polymer
class DomProxyMixin {
  js.JsObject _proxy;
  js.JsObject get jsElement {
    if (_proxy == null) {
      _proxy = new js.JsObject.fromBrowserObject(this);
    }
    return _proxy;
  }
}

/// A mixin to make it easier to interoperate with Polymer JS elements. This
/// exposes only a subset of the public api that is most useful from external
/// elements.
abstract class PolymerProxyMixin implements DomProxyMixin {
  /// The underlying Js Element's `$` property.
  js.JsObject get $ => jsElement[r'$'];

  /// By default the data bindings will be cleaned up when this custom element
  /// is detached from the document. Overriding this to return `true` will
  /// prevent that from happening.
  bool get preventDispose => jsElement['preventDispose'];
  set preventDispose(bool newValue) => jsElement['preventDispose'] = newValue;

  /// Force any pending property changes to synchronously deliver to handlers
  /// specified in the `observe` object. Note, normally changes are processed at
  /// microtask time.
  ///
  // Dart note: renamed to `deliverPropertyChanges` to be more consistent with
  // other polymer.dart elements.
  void deliverPropertyChanges() {
    jsElement.callMethod('deliverChanges', []);
  }

  /// Inject HTML which contains markup bound to this element into a target
  /// element (replacing target element content).
  DocumentFragment injectBoundHTML(String html, [Element element]) =>
      jsElement.callMethod('injectBoundHTML', [html, element]);

  /// Creates dom cloned from the given template, instantiating bindings with
  /// this element as the template model and `PolymerExpressions` as the binding
  /// delegate.
  DocumentFragment instanceTemplate(Element template) =>
      jsElement.callMethod('instanceTemplate', [template]);

  /// This method should rarely be used and only if `cancelUnbindAll` has been
  /// called to prevent element unbinding. In this case, the element's bindings
  /// will not be automatically cleaned up and it cannot be garbage collected by
  /// by the system. If memory pressure is a concern or a large amount of
  /// elements need to be managed in this way, `unbindAll` can be called to
  /// deactivate the element's bindings and allow its memory to be reclaimed.
  void unbindAll() => jsElement.callMethod('unbindAll', []);

  /// Call in `detached` to prevent the element from unbinding when it is
  /// detached from the dom. The element is unbound as a cleanup step that
  /// allows its memory to be reclaimed. If `cancelUnbindAll` is used, consider
  ///calling `unbindAll` when the element is no longer needed. This will allow
  ///its memory to be reclaimed.
  void cancelUnbindAll() => jsElement.callMethod('cancelUnbindAll', []);
}

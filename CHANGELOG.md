## 0.2.3
  * Added an "overrides" option to completely overrides code generation

## 0.2.2+1
  
  * Update for `path` API changes 

## 0.2.2

  * Added a new option to add extra imports on the dart side. Usefull when
    the generated import is wrong and you need to omit it and replace with
    the right one:

      - some_file/some_file.html:
         extra_imports:
          - package:polymer_elements/iron_resizable_behavior.dart
         
# 0.2.1+1
  * Make sure we handle duplicate behavior/element names that come back from the
    `hydrolysis` tool. This happens when there is an `Impl` class and a public
    class by the same name.

## 0.2.1
  * Added `type_overrides` option, which allows you to override types for any
    fields in a class. This may later be extended to allow you to override the
    return types and argument types of methods as well, if needed. This should
    be supplied as an option to a file, and should look like the following:
    
      - some_file/some_file.html:
          type_overrides:
            SomeClassInMyFile:
              somePropertyName:
                type: Number

## 0.2.0+2
  * Allow setting list/map properties to null.
  * Don't re-jsify a JsArray in setters.
  * Add support for deeply nested behaviors.

## 0.2.0+1
  * Remove `void` return types from all functions, and leave them as dynamic
    instead. It is too common for js methods to be marked as having no return
    type when they in fact do return something :(.

## 0.2.0
  * Update to polymer js 1.0 versions of polymer_interop and web_components
    packages. Not compatible with 0.5 elements, they should remain on 0.1.7.
    
## 0.1.7+1
  * Add back `common.dart` since old generated elements import it.
    This will be deleted in the next breaking release.

## 0.1.7
  * Use `CustomElementProxyMixin` from `web_components` instead of
    `DomProxyMixin`.
  * Moved `PolymerProxyMixin` to the `polymer_interop` package.
  * Point to `polymer.html` from the `polymer_interop` package instead of the
    `polymer` package.

## 0.1.6
  * Added `files_to_load` option to config files. Any files listed will be
    loaded but not generated. Any mixins which come from another package and are
    stubbed out will need to be loaded this way.

## 0.1.5
  * Add `Element` as dart type for `Element` js type.

## 0.1.5
  * Support `file_overrides` option for each html file listed in config files.
    This should be a map of file name prefixes to a list of class names. All
    classes listed will be output to the corresponding file instead of the
    default one.

## 0.1.4+3
  * Make the parser a bit more lenient around parsing mixins. The name is only
    parsed up to the first space, which allows for comments or other things
    to follow the name.

## 0.1.4+2
  * Switch from `html5lib` to `html` package dependency.

## 0.1.4+1
  * Update `web_components` constraint.

## 0.1.4
  * Start using @HtmlImport and @CustomElementProxy. This should have no effect
    on existing applications, other than enabling them to remove some of their
    html imports if desired (a dart import alone is now sufficient).

## 0.1.3
  * Add support for various methods and properties from the Polymer base class.
  * Add support for mixins.

## 0.1.2+1
  * Increase upper bound on web_components to `<0.11.0`.

## 0.1.2
  * Add support for the `$` property.

## 0.1.1
  * Automatically include `packages/web_components/interop_support.html`.

## 0.1.0

  * **Breaking Change** Removed main() from `generate_dart_api`, 
    `pub run custom_elements_apigen:update ...` is now the only way you should
    generate wrappers.
  * **Breaking Change** `deletion_patterns` option will now delete folders that
    match the supplied patterns as well as files.
  * **Breaking Change** Many functions in `generate_dart_api` were moved to be
    private.

## 0.0.3

Added deletion_patterns option to the config. This is a list of regex patterns
that match files under the lib/src directory. All matched files will be deleted,
and directories are skipped. This happens before the stubs are generated so they
will not be deleted if you list a folder containing a stub.

## 0.0.2+1

Updated polymer dependency.

## 0.0.2

Elements can now be built from code using a normal factory constructor, such as 
`new FooElement()`. It is still necessary however to include the html import for
each element you wish to create this way.

## 0.0.1

Initial version

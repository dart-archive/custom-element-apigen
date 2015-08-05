// Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
// This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
// The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
// The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
// Code distributed by Google as part of the polymer project is also
// subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt

/// AST nodes to represent the API of a Javascript polymer custom element. This
/// is parsed from documentation found in polymer elements and then it is used
/// to autogenerate a Dart API for them.
library custom_element_apigen.src.ast;

class FileSummary {
  String path;
  List<Import> imports = [];
  Map<String, Element> elementsMap = {};
  Map<String, Mixin> mixinsMap = {};

  FileSummary.fromJson(Map jsonSummary) {
    imports = jsonSummary['imports'].map((path) => new Import(path)).toList();

    for (Map element in jsonSummary['elements']) {
      elementsMap[element['name']] = new Element.fromJson(element);
    }

    for (Map mixinMap in jsonSummary['behaviors']) {
      var mixin = new Mixin.fromJson(mixinMap);
      mixinsMap[mixin.name] = mixin;
    }

    path = jsonSummary['path'];
  }

  Iterable<Element> get elements => elementsMap.values;
  Iterable<Mixin> get mixins => mixinsMap.values;

  String toString() =>
      'imports:\n$imports, elements:\n$elements, mixins:\n$mixins';

  /// Splits this summary into multiple summaries based on [file_overrides]. The
  /// keys are file names and the values are classes that should live in that
  /// file. All remaining files will end up in the [null] key.
  Map<String, FileSummary> splitByFile(
      Map<String, List<String>> file_overrides) {
    if (file_overrides == null) return {null: this};

    var summaries = {};
    var remainingElements = new Map.from(elementsMap);
    var remainingMixins = new Map.from(mixinsMap);

    /// Removes [names] keys from [original] and returns a new [Map] with those
    /// removed values.
    Map<String, Class> removeFromMap(
        Map<String, Class> original, List<String> names) {
      var newMap = {};
      for (var name in names) {
        var val = original.remove(name);
        if (val != null) newMap[name] = val;
      }
      return newMap;
    }

    /// Builds a summary from this one given [classNames].
    FileSummary buildSummary(List<String> classNames) {
      return new FileSummary.fromJson({
        'imports': new List.from(imports),
        'elementsMap': removeFromMap(remainingElements, classNames),
        'mixinsMap': removeFromMap(remainingMixins, classNames)
      });
    }

    file_overrides.forEach((String path, List<String> classNames) {
      summaries[path] = buildSummary(classNames);
    });

    var defaultSummary = new FileSummary.fromJson({
      'imports': new List.from(imports),
      'elementsMap': remainingElements,
      'mixinsMap': remainingMixins,
    });

    summaries[null] = defaultSummary;

    return summaries;
  }
}

/// Base class for any entry we parse out of the HTML files.
abstract class Entry {
  String toString() {
    var sb = new StringBuffer();
    _prettyPrint(sb);
    return sb.toString();
  }

  void _prettyPrint(StringBuffer sb);
}

/// Common information to most entries (element, property, method, etc).
abstract class NamedEntry {
  final String name;
  String description;
  FileSummary summary;

  NamedEntry.fromJson(Map jsonNamedEntry)
      : name = jsonNamedEntry['name'].replaceFirst('Polymer.', ''),
        description = jsonNamedEntry['description'];
}

/// An entry that has type information (like arguments and properties).
abstract class TypedEntry extends NamedEntry {
  String type;

  TypedEntry.fromJson(Map jsonTypedEntry)
      : type = jsonTypedEntry['type'],
        super.fromJson(jsonTypedEntry);
}

/// An import to another html element.
class Import extends Entry {
  String importPath;
  Import(this.importPath);

  void _prettyPrint(StringBuffer sb) {
    sb.write('import: $importPath\n');
  }
}

class Class extends NamedEntry {
  // TODO(jakemac): Rename to `extendsName`.
  String extendName;
  final Map<String, Property> properties = {};
  final List<Method> methods = [];

  Class.fromJson(Map jsonClass) : super.fromJson(jsonClass) {
    extendName = jsonClass['extendsName'];

    for (Map property in jsonClass['properties']) {
      properties[property['name']] = new Property.fromJson(property);
    }

    for (Map method in jsonClass['methods']) {
      methods.add(new Method.fromJson(method));
    }
  }

  void _prettyPrint(StringBuffer sb) {
    sb.write('$name:\n');
    sb.write('properties:\n');
    for (var p in properties.values) {
      sb.write('    - ');
      p._prettyPrint(sb);
      sb.write('\n');
    }
    sb.write('methods:\n');
    for (var m in methods) {
      sb.write('    - ');
      m._prettyPrint(sb);
      sb.write('\n');
    }
    sb.writeln('extends: $extendName');
  }

  String toString() {
    var message = new StringBuffer();
    _prettyPrint(message);
    return message.toString();
  }
}

class Mixin extends Class {
  final List<String> additionalMixins;

  Mixin.fromJson(Map jsonMixin)
      : additionalMixins = _allMixinNames(jsonMixin['behaviors']),
        super.fromJson(jsonMixin);

  _prettyPrint(StringBuffer sb) {
    sb.writeln('**Mixin**');
    super._prettyPrint(sb);
  }

  String toString() {
    var message = new StringBuffer();
    _prettyPrint(message);
    return message.toString();
  }
}

/// Data about a custom-element.
class Element extends Class {
  final List<String> mixins;

  Element.fromJson(Map jsonElement)
      : mixins = _allMixinNames(jsonElement['behaviors']),
        super.fromJson(jsonElement);

  void _prettyPrint(StringBuffer sb) {
    sb.writeln('**Element**');
    super._prettyPrint(sb);
    sb.writeln('  mixins:\n');
    for (var mixin in mixins) {
      sb.writeln('    - $mixin');
    }
    sb.writeln('  extends: $extendName');
  }

  String toString() {
    var message = new StringBuffer();
    _prettyPrint(message);
    return message.toString();
  }
}

/// Data about a property.
class Property extends TypedEntry {
  bool hasGetter;
  bool hasSetter;

  Property.fromJson(Map jsonProperty) : super.fromJson(jsonProperty) {
    hasGetter = jsonProperty['hasGetter'];
    hasSetter = jsonProperty['hasSetter'];
  }

  void _prettyPrint(StringBuffer sb) {
    sb.write('$type $name;');
  }
}

/// Data about a method.
class Method extends TypedEntry {
  bool isVoid = true;
  List<Argument> args = [];
  List<Argument> optionalArgs = [];

  Method.fromJson(Map jsonMethod) : super.fromJson(jsonMethod) {
    isVoid = jsonMethod['isVoid'];

    for (Map arg in jsonMethod['args']) {
      args.add(new Argument.fromJson(arg));
    }

    // TODO(jakemac): Support optional args.
  }

  void _prettyPrint(StringBuffer sb) {
    if (isVoid) sb.write('void ');
    sb.write('$name(');

    bool first = true;
    for (var arg in args) {
      if (!first) sb.write(',');
      first = false;
      arg._prettyPrint(sb);
    }

    bool firstOptional = true;
    for (var arg in optionalArgs) {
      if (firstOptional) {
        if (!first) sb.write(',');
        sb.write('[');
      } else {
        sb.write(',');
      }
      first = false;
      firstOptional = false;
      arg._prettyPrint(sb);
    }
    if (!firstOptional) sb.write(']');

    sb.write(');');
  }
}

/// Collects name and type information for arguments.
class Argument extends TypedEntry {
  Argument.fromJson(Map jsonArgument) : super.fromJson(jsonArgument);

  void _prettyPrint(StringBuffer sb) {
    if (type != null) {
      sb
        ..write(type)
        ..write(' ');
    }
    sb.write(name);
  }
}

List _flatten(List items) {
  var flattened = [];

  addAll(items) {
    for (var item in items) {
      if (item is List) {
        addAll(item);
      } else {
        flattened.add(item);
      }
    }
  }
  addAll(items);

  return flattened;
}

List<String> _allMixinNames(List behaviorNames) {
  if (behaviorNames == null) return null;
  var names = [];
  for (String mixin in _flatten(behaviorNames)) {
    names.add(mixin.replaceFirst('Polymer.', ''));
  }
  return names;
}

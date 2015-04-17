// Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
// This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
// The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
// The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
// Code distributed by Google as part of the polymer project is also
// subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt

/// Methods to generate code from previously collected information.
library custom_element_apigen.src.codegen;

import 'package:path/path.dart' as path;
import 'package:polymer/html_element_names.dart';

import 'config.dart';
import 'ast.dart';

String generateClass(Class classSummary, FileConfig config,
    Map<String, Element> elementSummaries, Map<String, Mixin> mixinSummaries) {
  var sb = new StringBuffer();
  var comment = _toComment(classSummary.description);
  var baseExtendName;
  if (classSummary is Element) {
    baseExtendName = _baseExtendName(classSummary.extendName, elementSummaries);
    sb.write(_generateElementHeader(classSummary.name, comment,
        classSummary.extendName, baseExtendName, classSummary.mixins
            .map((String name) => mixinSummaries[name])
            .toList()));
  } else if (classSummary is Mixin) {
    sb.write(_generateMixinHeader(
        classSummary.name, classSummary.extendName, comment));
  } else {
    throw 'unsupported summary type: $classSummary';
  }

  var getDartName = _substituteFunction(config.nameSubstitutions);
  classSummary.properties.values
      .forEach((p) => _generateProperty(p, sb, getDartName));
  classSummary.methods.forEach((m) => _generateMethod(m, sb, getDartName));
  sb.write('}\n');
  return sb.toString();
}

String _baseExtendName(String extendName, Map<String, Element> allElements) {
  if (extendName == null || extendName.isEmpty) return null;
  var baseExtendName = extendName;
  var baseExtendElement = allElements[baseExtendName];
  while (baseExtendElement != null &&
      baseExtendElement.extendName != null &&
      !baseExtendElement.extendName.isEmpty) {
    baseExtendName = baseExtendElement.extendName;
    baseExtendElement = allElements[baseExtendName];
  }
  return baseExtendName;
}

Function _substituteFunction(Map<String, String> nameSubstitutions) {
  if (nameSubstitutions == null) return (x) => x;
  return (x) {
    var v = nameSubstitutions[x];
    return v != null ? v : x;
  };
}

void _generateProperty(
    Property property, StringBuffer sb, String getDartName(String)) {
  var comment = _toComment(property.description, 2);
  var type = property.type;
  if (type != null) {
    type = _docToDartType[type.toLowerCase()];
  }
  var name = property.name;
  var dartName = getDartName(name);
  var body = "jsElement[r'$name']";
  sb.write(comment == '' ? '\n' : '\n$comment\n');
  var t = type != null ? '$type ' : '';
  sb.write('  ${t}get $dartName => $body;\n');

  // Don't output the setter if it has a getter but no setter in the original
  // source code. In all other cases we want a dart setter (normal js property
  // with no getter or setter, or custom property with a js setter).
  if (property.hasGetter && !property.hasSetter) return;
  if (type == null) {
    sb.write('  set $dartName(${t}value) { '
        '$body = (value is Map || value is Iterable) ? '
        'new JsObject.jsify(value) : value;}\n');
  } else if (type == "JsArray") {
    sb.write('  set $dartName(${t}value) { '
        '$body = (value is Iterable) ? '
        'new JsObject.jsify(value) : value;}\n');
  } else {
    sb.write('  set $dartName(${t}value) { $body = value; }\n');
  }
}

void _generateMethod(
    Method method, StringBuffer sb, String getDartName(String)) {
  var comment = _toComment(method.description, 2);
  sb.write(comment == '' ? '\n' : '\n$comment\n');
  for (var arg in method.args) {
    _generateArgComment(arg, sb);
  }
  for (var arg in method.optionalArgs) {
    _generateArgComment(arg, sb);
  }
  sb.write('  ');
  if (method.isVoid) sb.write('void ');
  var name = method.name;
  var dartName = getDartName(name);
  sb.write('$dartName(');
  var argList = new StringBuffer();
  // First do the regular args, then the optional ones if there are any.
  _generateArgList(method.args, sb, argList);
  if (!method.optionalArgs.isEmpty) {
    if (!method.args.isEmpty) {
      sb.write(', ');
      argList.write(', ');
    }
    sb.write('[');
    _generateArgList(method.optionalArgs, sb, argList);
    sb.write(']');
  }

  sb.write(") =>\n      jsElement.callMethod('$name', [$argList]);\n");
}

// Returns whether it found any args or not.
void _generateArgList(
    List<Argument> args, StringBuffer dartArgList, StringBuffer jsArgList) {
  bool first = true;
  for (var arg in args) {
    if (!first) {
      dartArgList.write(', ');
      jsArgList.write(', ');
    }
    first = false;
    var type = arg.type;
    if (type != null) {
      type = _docToDartType[type.toLowerCase()];
    }
    if (type != null) {
      dartArgList
        ..write(type)
        ..write(' ');
    }
    dartArgList.write(arg.name);
    jsArgList.write(arg.name);
  }
}

String generateDirectives(String name, List<String> segments,
    FileSummary summary, FileConfig config, String packageLibDir,
    Map<String, Mixin> mixinSummaries) {
  var libName = name.replaceAll('-', '_');
  var extraImports = new Set<String>();

  for (var element in summary.elements) {
    var extendName = element.extendName;
    if (extendName != null && extendName.contains('-')) {
      var extendsImport = config.extendsImport;
      if (extendsImport == null) {
        var packageName = config.global.findPackageNameForElement(extendName);
        var fileName = '${extendName.replaceAll('-', '_')}.dart';
        extendsImport =
            packageName != null ? 'package:$packageName/$fileName' : fileName;
      }
      extraImports.add("import '$extendsImport';");
    }

    for (var mixinName in element.mixins) {
      extraImports.add(_generateMixinImport(mixinName, config));

      // Add imports for things each mixin `extends`.
      var mixin = mixinSummaries[mixinName];
      if (mixin == null) {
        throw 'Unable to find mixin $mixinName. Make sure the mixin file is '
            'loaded. If you don\'t want to generate the mixin as a dart api '
            'then you can use the `files_to_load` section to load it.';
      }
      if (mixin.extendName == null) continue;
      extraImports.add(_generateMixinImport(mixin.extendName, config));
    }
  }

  // Add imports for things each mixin `extends`.
  for (var mixin in summary.mixins) {
    if (mixin.extendName == null) continue;
    extraImports.add(_generateMixinImport(mixin.extendName, config));
  }

  for (var import in summary.imports) {
    var htmlImport = getImportPath(import, config, segments, packageLibDir,
        isDartFile: true);
    if (htmlImport == null) continue;
    var dartImport = '${path.withoutExtension(htmlImport)}.dart';
    extraImports.add("import '$dartImport';");
  }

  var packageName = config.global.currentPackage;
  var output = new StringBuffer();
  output.write('''
// DO NOT EDIT: auto-generated with `pub run custom_element_apigen:update`

/// Dart API for the polymer element `$name`.
@HtmlImport('${libName}_nodart.html')
library $packageName.$libName;

import 'dart:html';
import 'dart:js' show JsArray, JsObject;
import 'package:web_components/web_components.dart';
import 'package:polymer_interop/polymer_interop.dart';
''');
  extraImports.forEach((import) => output.writeln(import));
  return output.toString();
}

String getImportPath(Import import, FileConfig config, List<String> segments,
    String packageLibDir, {bool isDartFile: false}) {
  var importPath = import.importPath;
  if (importPath.contains('polymer.html')) return null;
  var omit = config.omitImports;
  if (omit != null && omit.any((path) => importPath.contains(path))) {
    return null;
  }
  var importSegments = path.split(importPath);
  if (importSegments[0] == '..') {
    importSegments.removeRange(0, segments.length - 2);
  }
  var dartImport = path.joinAll(importSegments).replaceAll('-', '_');
  var targetElement = importSegments.last;
  var packageName = config.global.findPackageNameForElement(targetElement);
  if (packageName != null) {
    if (isDartFile) {
      dartImport = 'package:$packageName/$dartImport';
    } else {
      dartImport = path.join(
          '..', '..', packageLibDir, 'packages', packageName, dartImport);
    }
  } else {
    dartImport = path.join(packageLibDir, dartImport);
  }
  return dartImport;
}

String _generateMixinImport(String name, FileConfig config) {
  var packageName = config.global.findPackageNameForElement(name);
  var fileName = '${_toFileName(name)}.dart';
  var mixinImport =
      packageName != null ? 'package:$packageName/$fileName' : fileName;
  return "import '$mixinImport';";
}

String _generateMixinHeader(String name, String extendName, String comment) {
  var className = name.split('.').last;
  var maybeExtends = extendName == null ? '' : ', $extendName';
  return '''

$comment
abstract class $className implements CustomElementProxyMixin$maybeExtends {
''';
}

String _generateElementHeader(String name, String comment, String extendName,
    String baseExtendName, List<Mixin> mixins) {
  var className = _toCamelCase(name);

  var extendClassName;
  var hasCustomElementProxyMixin = false;
  if (extendName == null) {
    extendClassName =
        'HtmlElement with CustomElementProxyMixin, PolymerProxyMixin';
    hasCustomElementProxyMixin = true;
  } else if (!extendName.contains('-')) {
    extendClassName = '${HTML_ELEMENT_NAMES[baseExtendName]} with '
        'CustomElementProxyMixin, PolymerProxyMixin';
    hasCustomElementProxyMixin = true;
  } else {
    extendClassName = _toCamelCase(extendName);
  }

  var mixinNames = [];
  mixins.forEach((Mixin m) {
    if (m.extendName != null) mixinNames.add(m.extendName);
    mixinNames.add(m.name);
  });

  var optionalMixinString = mixinNames.isEmpty
      ? ''
      : '${hasCustomElementProxyMixin
          ? ', '
          : ' with '}${mixinNames.join(', ')}';

  var factoryMethod = new StringBuffer('factory ${className}() => ');
  if (baseExtendName == null || baseExtendName.contains('-')) {
    factoryMethod.write('new Element.tag(\'$name\');');
  } else {
    factoryMethod.write('new Element.tag(\'$baseExtendName\', \'$name\');');
  }

  var customElementProxy = _generateCustomElementProxy(name, baseExtendName);
  return '''

$comment
$customElementProxy
class $className extends $extendClassName$optionalMixinString {
  ${className}.created() : super.created();
  $factoryMethod
''';
}

String _generateCustomElementProxy(String name, String baseExtendName) {
  var className = _toCamelCase(name);
  // Only pass the extendsTag if its a native element.
  var maybeExtendsTag = '';
  if (baseExtendName != null && !baseExtendName.contains('-')) {
    maybeExtendsTag = ', extendsTag: \'$baseExtendName\'';
  }
  return "@CustomElementProxy('$name'$maybeExtendsTag)";
}

void _generateArgComment(Argument arg, StringBuffer sb) {
  var name = arg.name;
  var description = arg.description.trim();
  if (description == '') return;
  var comment = description.replaceAll('\n', '\n  ///     ');
  sb.write('  /// [${name}]: $comment\n');
}

String _toComment(String description, [int indent = 0]) {
  description = description.trim();
  if (description == '') return '';
  var s1 = ' ' * indent;
  var comment = description.split('\n').map((e) {
    var trimmed = e.trimRight();
    return trimmed == '' ? '' : ' $trimmed';
  }).join('\n$s1///');
  return '$s1///$comment';
}

String _toCamelCase(String dashName) => dashName
    .split('-')
    .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
    .join('');

String _toFileName(String className) {
  var fileName = new StringBuffer();
  for (var i = 0; i < className.length; ++i) {
    var lower = className[i].toLowerCase();
    if (i > 0 && className[i] != lower) fileName.write('_');
    fileName.write(lower);
  }
  return fileName.toString();
}

final _docToDartType = {
  'boolean': 'bool',
  'array': 'JsArray',
  'string': 'String',
  'number': 'num',
  'object': null, // keep as dynamic
  'any': null, // keep as dynamic
  'element': 'Element',
};

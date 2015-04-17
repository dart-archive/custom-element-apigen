// Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
// This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
// The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
// The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
// Code distributed by Google as part of the polymer project is also
// subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt

/// Helper to parse code generation configurations from a file.
library custom_element_apigen.src.config;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Holds the entire information parsed from the command line arguments and
/// configuration files.
class GlobalConfig {
  final List<FileConfig> files = [];
  final Map<String, String> stubs = {};
  final List<PackageMapping> packageMappings = [];
  final List<RegExp> deletionPatterns = [];
  final List<String> filesToLoad = [];
  String currentPackage;
  int _lastUpdated = 0;

  /// Retrieve the package name associated with [elementName].
  String findPackageNameForElement(String elementName) {
    if (_lastUpdated != packageMappings.length) {
      packageMappings.sort();
    }
    for (var mapping in packageMappings) {
      if (elementName.startsWith(mapping.prefix)) return mapping.packageName;
    }
    return null;
  }
}

class PackageMapping implements Comparable<PackageMapping> {
  String prefix;
  String packageName;

  PackageMapping(this.prefix, this.packageName);

  /// Sort in reverse order of the prefix to ensure that longer prefixes are
  /// matched first.
  int compareTo(PackageMapping other) => -prefix.compareTo(other.prefix);
}

/// Configuration information corresponding to a given HTML input file.
class FileConfig {
  final GlobalConfig global;

  /// The path to the original file.
  final String inputPath;

  /// Javascript names that should be substituted when generating Dart code.
  final Map<String, String> nameSubstitutions;

  /// HTML Imports that shold not be mirrored because they don't have a
  /// corresponding Dart type.
  final List<String> omitImports;

  /// Map of file names to classes that should live within them. All other
  /// classes will end up in the default file.
  final Map<String, List<String>> file_overrides;

  /// Dart import to get the base class of a custom element. This is inferred
  /// normally from the package_mappings, but can be overriden on an individual
  /// file if necessary.
  final String extendsImport;

  FileConfig(this.global, this.inputPath, [Map map])
      : nameSubstitutions = map != null ? map['name_substitutions'] : null,
        omitImports = map != null ? map['omit_imports'] : null,
        extendsImport = map != null ? map['extends_import'] : null,
        file_overrides = map != null ? map['file_overrides'] : null;
}

/// Parse configurations from a `.yaml` configuration file.
void parseConfigFile(String filePath, GlobalConfig config) {
  if (!new File(filePath).existsSync()) {
    print("error: file $filePath doesn't exist");
    exit(1);
  }
  var yaml = loadYaml(new File(filePath).readAsStringSync());
  _parsePackageMappings(yaml, config);
  _parseFilesToGenerate(yaml, config);
  _parseStubsToGenerate(yaml, config);
  _parseDeletionPatterns(yaml, config);
  _parseFilesToLoad(yaml, config);

  if (!new File('pubspec.yaml').existsSync()) {
    print("error: file 'pubspec.yaml' doesn't exist");
    exit(1);
  }
  yaml = loadYaml(new File('pubspec.yaml').readAsStringSync());
  config.currentPackage = yaml['name'];
}

void _parsePackageMappings(yaml, GlobalConfig config) {
  var packageMappings = yaml['package_mappings'];
  if (packageMappings == null) return;
  for (var entry in packageMappings) {
    if (entry is! YamlMap) continue;
    config.packageMappings
        .add(new PackageMapping(entry.keys.single, entry.values.single));
  }
}

void _parseFilesToGenerate(yaml, GlobalConfig config) {
  var toGenerate = yaml['files_to_generate'];
  if (toGenerate == null) return;
  for (var entry in toGenerate) {
    if (entry is String) {
      config.files.add(new FileConfig(config, path.join('lib', 'src', entry)));
      continue;
    }

    if (entry is! YamlMap) continue;
    if (entry.length != 1) {
      print('invalid format for: $entry');
      continue;
    }

    config.files.add(new FileConfig(config,
        path.join('lib', 'src', entry.keys.single), entry.values.single));
  }
}

void _parseStubsToGenerate(yaml, GlobalConfig config) {
  var toGenerate = yaml['stubs_to_generate'];
  if (toGenerate == null) return;
  if (toGenerate is! YamlMap) {
    print("error: bad configuration in stubs_to_generate");
    exit(1);
  }
  var map = toGenerate as YamlMap;
  for (var key in map.keys) {
    var value = map[key];
    if (value is String) {
      config.stubs[path.join('lib', 'src', value)] = key;
      continue;
    }
    if (value is YamlList) {
      for (var entry in value) {
        config.stubs[path.join('lib', 'src', entry)] = key;
      }
    }
  }
}

void _parseDeletionPatterns(yaml, GlobalConfig config) {
  var patterns = _parseStringList(yaml, 'deletion_patterns');
  if (patterns == null) return;
  config.deletionPatterns
      .addAll((patterns as YamlList).map((pattern) => new RegExp(pattern)));
}

void _parseFilesToLoad(yaml, GlobalConfig config) {
  var filePaths = _parseStringList(yaml, 'files_to_load');
  if (filePaths == null) return;
  config.filesToLoad.addAll(filePaths.map((filePath) {
    var parts = filePath.split(':');
    if (parts.length == 1) {
      return platformIndependentPath(parts[0]);
    } else if (parts.length == 2 && parts[0] == 'package') {
      return path.join('packages', platformIndependentPath(parts[1]));
    } else {
      throw 'Unrecognized path `$filePath`. Should be a relative uri or a '
          '`package:` style uri.';
    }
  }));
}

String platformIndependentPath(String originalPath) =>
    path.joinAll(path.url.split(originalPath));

List<String> _parseStringList(yaml, String name) {
  var items = yaml[name];
  if (items == null) return null;
  if (items is! YamlList || (items as YamlList).any((e) => e is! String)) {
    print('Unrecognized $name setting, expected a list of Strings');
    exit(1);
  }
  return items;
}

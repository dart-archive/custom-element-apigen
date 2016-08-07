@TestOn('vm')
library custom_element_apigen.test.behavior_test;

import 'dart:io';
import 'package:custom_element_apigen/generate_dart_api.dart';
import 'package:test/test.dart';
import 'mock_file.dart';

_mockFileFactory(String path) => new MockFile(path);

main() {
  test('can generate wrappers', () async {
    var config = parseArgs(['behavior_config.yaml'], '');
    await generateWrappers(config, createFile: _mockFileFactory);
    expectFilesCreated('example_behavior');
    expectFilesCreated('example_element');
    expectFilesCreated('example_element_with_behavior');
    expectFilesCreated('example_multi_behavior');
    expectFilesCreated('example_multi_deep_behavior');
    expectFilesCreated('example_element_with_deep_behavior');
    expectFilesCreated('example_element_with_overrides');
  });
}

void expectFilesCreated(String name) {
  void expectContainsFile(String path) {
    expect(MockFile.createdFiles.any((f) => f.path == path), isTrue);
  }

  expectContainsFile('lib/$name.html');
  expectContainsFile('lib/${name}_nodart.html');
  expectContainsFile('lib/$name.dart');
  expect(
      MockFile.createdFiles
          .firstWhere((f) => f.path == 'lib/$name.dart')
          .contents,
      readExpected(name));
}

String readExpected(String name) =>
    new File('test/expected/$name.dart').readAsStringSync();

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
    await generateWrappers(config, fileFactory: _mockFileFactory);
    expectFilesCreated('my_behavior');
    expectFilesCreated('my_element');
//    expectFilesCreated('my_element_with_behavior');
  });
}

void expectFilesCreated(String name) {
  void expectContainsFile(String path) {
    expect(MockFile.createdFiles.any((f) => f.path == path), isTrue);
  }

  expectContainsFile('lib/$name.html');
  expectContainsFile('lib/${name}_nodart.html');
  expectContainsFile('lib/$name.dart');
  expect(MockFile.createdFiles
          .firstWhere((f) => f.path == 'lib/$name.dart').contents,
      readExpected(name));
}

String readExpected(String name) =>
    new File('test/expected/$name.dart').readAsStringSync();

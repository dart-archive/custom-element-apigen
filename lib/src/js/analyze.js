var hyd = require('hydrolysis');

var filePath = process.argv[2];

hyd.Analyzer.analyze(filePath)
    .then(function(results) {
      console.log(JSON.stringify({
        imports: results.html[filePath].depHrefs,
        elements: getElements(results, filePath),
        behaviors: getBehaviors(results, filePath)
      }));
    });

function getElements(results, filePath) {
  var elements = [];
  for (var e = 0; e < results.elements.length; e++) {
    var element = results.elements[e];
    if (element.contentHref != filePath) continue;

    elements.push({
      extendsName: getExtendsName(element),
      name: element.is,
      properties: getProperties(element),
      methods: getMethods(element),
      description: element.desc,
      behaviors: element.behaviors || []
    });
  }
  return elements;
}

function getBehaviors(results, filePath) {
  var behaviors = [];
  if (!results.behaviors) return behaviors;
  for (var b = 0; b < results.behaviors.length; b++) {
    var behavior = results.behaviors[b];
    if (behavior.contentHref != filePath) continue;

    behaviors.push({
      name: behavior.is,
      properties: getProperties(behavior),
      methods: getMethods(behavior),
      description: behavior.desc
    });
  }
  return behaviors;
}

function getProperties(element) {
  var properties = [];
  for (var i = 0; i < element.properties.length; i++) {
    var property = element.properties[i];
    if (isPrivate(property) || !isField(property)) continue;
    if (property.name == 'extends') continue;
    if (containsProperty(properties, property.name)) continue;

    properties.push({
      hasGetter: !property.function || isGetter(property) ||
          (isSetter(property) && hasPropertyGetter(element, property.name)),
      hasSetter: !property.function || isSetter(property) ||
          (isGetter(property) && hasPropertySetter(element, property.name)),
      name: property.name,
      type: getFieldType(property),
      description: property.desc || ''
    });
  }
  return properties;
}

function getFieldType(property) {
  if (isGetter(property)) return property.return ? property.return.type : null;
  if (isSetter(property)) return property.params[0].type;
  return property.type;
}

function getMethods(element) {
  var methods = [];
  for (var i = 0; i < element.properties.length; i++) {
    var property = element.properties[i];
    if (isPrivate(property) || !isMethod(property)) continue;

    methods.push({
      name: property.name,
      type: property.return ? property.return.type : null,
      description: property.desc || '',
      isVoid: !property.return,
      args: getArguments(property)
    });
  }
  return methods;
}

function getArguments(func) {
  var args = [];
  for (var i = 0; i < func.params.length; i++) {
    var param = func.params[i];
    args.push({
      name: param.name,
      description: param.desc || '',
      type: param.type
    });
  }
  return args;
}

function getExtendsName(element) {
  for (var i = 0; i < element.properties.length; i++) {
    var prop = element.properties[i];
    if (prop.name == 'extends') {
      return prop.javascriptNode.value.value;
    }
  }
}

function isPrivate(property) {
  return property.name.length > 0 && property.name[0] == '_';
}

function isMethod(property) {
  if (!property.function) return false;
  return !isGetter(property) && !isSetter(property);
}

function isField(property)  {
  if (!property.function) return true;
  return isGetter(property) || isSetter(property);
}

function isGetter(field) {
  if (!field.function) return false;
  return field.javascriptNode.kind == 'get';
}

function isSetter(field) {
  if (!field.function) return false;
  return field.javascriptNode.kind == 'set';
}

function containsProperty(properties, name) {
  for (var i = 0; i < properties.length; i++) {
    if (properties[i].name == name) return true;
  }
  return false;
}

function hasPropertySetter(element, name) {
  for (var i = 0; i < element.properties.length; i++) {
    var prop = element.properties[i];
    if (prop.name == name && prop.function && prop.javascriptNode.kind == 'set')
        return true;
  }
  return false;
}

function hasPropertyGetter(element, name) {
  for (var i = 0; i < element.properties.length; i++) {
    var prop = element.properties[i];
    if (prop.name == name && prop.function && prop.javascriptNode.kind == 'get')
        return true;
  }
  return false;
}

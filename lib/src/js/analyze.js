var hyd = require('hydrolysis');

var filePath = process.argv[2];


try {
  hyd.Analyzer.analyze(filePath)
      .then(function (results) {
        console.log(JSON.stringify({
          imports: results.html[filePath].depHrefs,
          elements: getElements(results, filePath),
          behaviors: getBehaviors(results, filePath),
          path: filePath
        }));
      });
} catch(e) {
  console.log(e);
}
function getElements(results, filePath) {
  var elements = {};
  if (!results.elements) return elements;
  for (var e = 0; e < results.elements.length; e++) {
    var element = results.elements[e];
    if (element.contentHref != filePath) continue;
    var className = toCamelCase(element.is);
    if (elements[className]) continue;

    elements[className] = {
      extendsName: getExtendsName(element),
      name: element.is,
      properties: getProperties(element),
      methods: getMethods(element),
      description: element.desc,
      behaviors: element.behaviors || []
    };
  }
  return elements;
}

function getBehaviors(results, filePath) {
  var behaviors = {};
  if (!results.behaviors) return behaviors;
  for (var b = 0; b < results.behaviors.length; b++) {
    var behavior = results.behaviors[b];
    if (behavior.contentHref != filePath) continue;
    var name = behavior.is.replace('Polymer.', '');
    if (behaviors[name]) continue;

    behaviors[name] = {
      name: name,
      properties: getProperties(behavior),
      methods: getMethods(behavior),
      description: behavior.desc,
      behaviors: behavior.behaviors
    };
  }
  return behaviors;
}

function getProperties(element) {
  var properties = {};
  if (!element.properties) return properties;
  for (var i = 0; i < element.properties.length; i++) {
    var property = element.properties[i];
    if (isPrivate(property) || !isField(property)) continue;
    if (property.name == 'extends') continue;
    if (properties[property.name]) continue;

    properties[property.name] = {
      hasGetter: !property.function || isGetter(property) ||
          (isSetter(property) && hasPropertyGetter(element, property.name)),
      hasSetter: !property.function || isSetter(property) ||
          (isGetter(property) && hasPropertySetter(element, property.name)),
      name: property.name,
      type: getFieldType(property),
      description: property.desc || ''
    };
  }
  return properties;
}

function getFieldType(property) {
  if (isGetter(property)) return property.return ? property.return.type : null;
  if (isSetter(property)) return property.params[0].type;
  return property.type;
}

function getMethods(element) {
  var methods = {};
  if (!element.properties) return methods;
  for (var i = 0; i < element.properties.length; i++) {
    var property = element.properties[i];
    if (isPrivate(property) || !isMethod(property)) continue;
    if (methods[property.name]) continue;

    methods[property.name] = {
      name: property.name,
      type: property.return ? property.return.type : null,
      description: property.desc || '',
      isVoid: !property.return,
      args: getArguments(property)
    };
  }
  return methods;
}

function getArguments(func) {
  var args = [];
  if (!func.params) return args;
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
  if (!element.properties) return null;
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

function toCamelCase(dashName) {
  return dashName.split('-').map(function (e) {
    return e.substring(0, 1).toUpperCase() + e.substring(1);
  }).join('');
}

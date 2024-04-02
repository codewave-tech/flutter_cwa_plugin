// ignore_for_file: public_member_api_docs, sort_constructors_first, no_leading_underscores_for_local_identifiers

import 'package:flutter_cwa_plugin/commands/j2m/j2m_name_converter.dart';
import 'package:flutter_cwa_plugin/commands/j2m/j2m_normalizer.dart';

class J2mConverter {
  Set<String> generatedClasses = {};
  String generateModel(Map<String, dynamic> mp, String className) {
    J2mNormalizer.normalizeMap(mp, mp, []);

    Map<String, List<ClassProperty>> classPropertyMap =
        generateClassProperties(mp, className);

    return _generateModels(classPropertyMap);
  }

  String _generateModels(Map<String, List<ClassProperty>> classPropertyMap) {
    StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln('import \'package:cw_core/cw_core.dart\';');
    classPropertyMap.forEach((key, value) {
      // class name
      stringBuffer.writeln('class $key {');

      // properties
      for (int idx = 0; idx < value.length; idx++) {
        stringBuffer
            .writeln('final ${value[idx].type} ${value[idx].properyName};');
      }

      // constructor
      stringBuffer.writeln('$key({');

      for (int idx = 0; idx < value.length; idx++) {
        stringBuffer.writeln('required this.${value[idx].properyName},');
      }

      stringBuffer.writeln('});');

      // factory constructor
      stringBuffer.writeln('factory $key.fromJson(Map<String,dynamic> json) {');
      stringBuffer.writeln('JsonParser parser = JsonParser(json);');
      stringBuffer.writeln('return $key(');

      for (int idx = 0; idx < value.length; idx++) {
        stringBuffer.writeln(
            '${value[idx].properyName} : ${value[idx].converterMethodSignature},');
      }

      stringBuffer.writeln(');');
      stringBuffer.writeln('}');
      stringBuffer.writeln('}');
    });

    return stringBuffer.toString();
  }

  Map<String, List<ClassProperty>> generateClassProperties(
    Map<String, dynamic> mp,
    String modelName,
  ) {
    Map<String, List<ClassProperty>> classPropertyMap = {};

    _generateClassProperties(
      classPropertyMap: classPropertyMap,
      mp: mp,
      className: modelName,
    );

    return classPropertyMap;
  }

  void _generateClassProperties({
    required Map<String, List<ClassProperty>> classPropertyMap,
    required Map<String, dynamic> mp,
    required String className,
  }) {
    List<ClassProperty> properties = [];
    mp.forEach((key, value) {
      /// property data
      String? _name;
      String? _type;
      String? _converterMethodSignature;

      if (value is List) {
        if (value.isNotEmpty) {
          if (_isPrimitive(value[0])) {
            _type = "List<${_getPrimitiveDartType(value[0])}>?";
            _name = key;
            _converterMethodSignature =
                "parser.list<${_getPrimitiveDartType(value[0])}>(\"$key\")";
          } else if (value[0] is Map) {
            String className = J2mNameConverter.toClassName(
              key,
              isArray: true,
            );

            _name = key;
            _type = "List<$className?>?";
            _converterMethodSignature =
                "parser.list<$className?>(\"$key\",create: (v) => $className.fromJson(v),)";
            _generateClassProperties(
              classPropertyMap: classPropertyMap,
              mp: value[0],
              className: className,
            );
          } else {
            _name = key;
            _type = "List<dynamic>";
            _converterMethodSignature = "List<dynamic>.from(json[\"$key\"])";
          }
        }
      } else if (value is Map) {
        String className = J2mNameConverter.toClassName(key);
        _name = key;
        _type = "$className?";
        _converterMethodSignature =
            "parser.single<$_type>(\"$key\",create: (v) => $_type.fromJson(v),)";

        _generateClassProperties(
          classPropertyMap: classPropertyMap,
          mp: value as Map<String, dynamic>,
          className: className,
        );
      } else {
        _type = _getPrimitiveDartType(value);
        _name = key;
        _converterMethodSignature = "parser.single<$_type>(\"$key\")";
      }

      properties.add(ClassProperty(
        name: _name!,
        type: _type!,
        converterMethodSignature: _converterMethodSignature!,
        properyName: J2mNameConverter.toPropertyName(key),
      ));
    });
    classPropertyMap[className] = properties;
  }

  // ClassProperty _recurseArray({
  //   required ClassProperty classProperty,
  //   required List<dynamic> arr,
  //   required Map<String, List<ClassProperty>> classPropertyMap,
  // }) {}

  bool _isPrimitive(dynamic value) =>
      (value is double || value is int || value is String || value is bool);

  String _getPrimitiveDartType(dynamic value) {
    if (value is double || value is int) return "num?";
    if (value is String) return "String?";
    if (value is bool) return "bool?";
    return "dynamic";
  }
}

class ClassProperty {
  final String name;
  final String properyName;
  final String type;
  final String converterMethodSignature;

  ClassProperty({
    required this.name,
    required this.properyName,
    required this.type,
    required this.converterMethodSignature,
  });
}

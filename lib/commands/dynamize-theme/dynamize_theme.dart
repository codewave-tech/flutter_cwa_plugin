import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:cwa_plugin_core/cwa_plugin_core.dart';

class ArchBuddyDynamizeTheme extends Command {
  ArchBuddyDynamizeTheme(super.args);

  final String appThemeFile = 'lib/core/themes/app_theme.dart';

  final String dynamicThemeFile = 'lib/core/themes/dynamic_theme.dart';

  @override
  Future<void> run() async {
    CWLogger.i.progress("Analyzing app_theme.dart");
    File file = File(appThemeFile);
    bool exists = await file.exists();
    if (!exists) {
      CWLogger.i.stderr("app_theme.dart not found in lib/core/themes");
      exit(2);
    }

    ParseStringResult result = parseFile(
      path: appThemeFile,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    Map<String, String> varNameToClassMap = {};
    result.unit
        .visitChildren(AppThemesVisitor(varNameToClassMap: varNameToClassMap));

    CWLogger.i.progress('Generating dynamic theme file');
    await createDynamicThemeClass(varNameToClassMap);
  }

  Future<void> createDynamicThemeClass(
      Map<String, String> varNameToClassMap) async {
    StringBuffer dynamicClassContentBuffer = StringBuffer();

    dynamicClassContentBuffer.writeln("import 'app_theme.dart';");
    dynamicClassContentBuffer
        .writeln("import 'package:flutter/material.dart' show Color;");

    dynamicClassContentBuffer
        .writeln('class DynamicTheme  implements AppThemes {');
    varNameToClassMap.forEach((key, value) {
      dynamicClassContentBuffer.writeln('@override');
      dynamicClassContentBuffer.writeln('final $value $key;');
    });

    dynamicClassContentBuffer.writeln('\n');
    dynamicClassContentBuffer.writeln('DynamicTheme({');
    varNameToClassMap.forEach((key, value) {
      dynamicClassContentBuffer.writeln('required this.$key,');
    });
    dynamicClassContentBuffer.writeln('});');

    dynamicClassContentBuffer.writeln('\n');

    dynamicClassContentBuffer.writeln(
        'factory DynamicTheme.fromJson(Map<String,dynamic> json) => DynamicTheme(');

    varNameToClassMap.forEach((key, value) {
      if (value.contains('Color')) {
        dynamicClassContentBuffer.writeln("$key : _hexToColor(json['$key']),");
      } else {
        dynamicClassContentBuffer.writeln("$key : json['$key'],");
      }
    });

    dynamicClassContentBuffer.writeln(');');

    dynamicClassContentBuffer.write(r'''
          static Color _hexToColor(String hexString) {
              hexString = hexString.replaceFirst('#', '');
              if (hexString.length == 6) {
                hexString = 'FF$hexString';
              }
              return Color(int.parse(hexString, radix: 16));
            }
    ''');

    dynamicClassContentBuffer.writeln('Map<String,dynamic> toJson() => {');

    varNameToClassMap.forEach((key, value) {
      if (value.contains('Color')) {
        dynamicClassContentBuffer.writeln("\"$key\" : colorToHex($key),");
      } else {
        dynamicClassContentBuffer.writeln("\"$key\" : $key,");
      }
    });

    dynamicClassContentBuffer.writeln('};');

    dynamicClassContentBuffer.write(r'''
         String colorToHex(Color color) {
            String redHex = color.red.toRadixString(16).padLeft(2, '0');
            String greenHex = color.green.toRadixString(16).padLeft(2, '0');
            String blueHex = color.blue.toRadixString(16).padLeft(2, '0');
            return '#$redHex$greenHex$blueHex';
          }
    ''');

    dynamicClassContentBuffer.writeln('}');

    await File(dynamicThemeFile)
        .writeAsString(dynamicClassContentBuffer.toString());
    await Process.run('dart', ['format', dynamicThemeFile]);
    CWLogger.namedLog(
      "Dynamic theme code has been successfully generated at $dynamicThemeFile",
      loggerColor: CWLoggerColor.green,
    );
  }
}

class AppThemesVisitor extends RecursiveAstVisitor<void> {
  final Map<String, String> varNameToClassMap;

  AppThemesVisitor({required this.varNameToClassMap});
  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.name.toString() == 'AppThemes') {
      CWLogger.i.trace('Found AppThemes class');
      for (var member in node.members) {
        if (member is MethodDeclaration && member.isGetter) {
          varNameToClassMap[member.name.toString()] =
              member.returnType.toString();

          CWLogger.i
              .trace('Getter found: ${member.returnType} ${member.name} ');
        }
      }
    }
    super.visitClassDeclaration(node);
  }
}

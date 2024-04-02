// ignore_for_file: public_member_api_docs, sort_constructors_first
part of mlg_command;

extension AppStringAnalyzer on ArchBuddyMLG {
  Future<AppStringContext> analyzeAppStringFile(String path) async {
    File appStringFile = File(path);
    if (!appStringFile.existsSync()) {
      CWLogger.namedLog("app_strings.dart file missing");
      exit(2);
    }

    CWLogger.i.progress("Analyzing app_strings.dart");
    String fileContent = await appStringFile.readAsString();
    var result = parseString(
      content: fileContent,
      featureSet: FeatureSet.latestLanguageVersion(),
    );

    Map<String, AppStringNode> nodeHashMp = {};

    LineInfo lineInfo = result.lineInfo;
    result.unit.visitChildren(AppStringClassVisitor(
      nodeHashMp: nodeHashMp,
      lineInfo: lineInfo,
    ));

    return AppStringContext.fromNodeHashMap(
      nodeHashMap: nodeHashMp,
      stringSanitizer: removeQuotes,
    );
  }
}

class AppStringClassVisitor extends RecursiveAstVisitor<void> {
  final LineInfo lineInfo;
  final Map<String, AppStringNode> nodeHashMp;
  final List<String> _allowedTypes = ['String', 'int', 'double'];

  AppStringClassVisitor({
    required this.nodeHashMp,
    required this.lineInfo,
  });

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.name.toString() == 'AppStrings') {
      for (ClassMember member in node.members) {
        // Filter methods with allowed return types
        if (member is MethodDeclaration &&
            _allowedTypes.contains(member.returnType.toString()) &&
            (member.name.toString() != 'of' &&
                member.name.toString() != 'ofUntranslated')) {
          String returnType = member.returnType.toString();
          String methodName = member.name.toString();
          String? parameters = member.parameters?.toSource();

          // Check for a direct return of a string literal
          bool isBlockBody = member.body is! ExpressionFunctionBody;
          String funcBody = '';

          if (!isBlockBody) {
            ExpressionFunctionBody body = member.body as ExpressionFunctionBody;
            funcBody = body.expression.toSource();
          } else {
            BlockFunctionBody body = (member.body as BlockFunctionBody);
            CharacterLocation location = lineInfo.getLocation(body.offset);
            StringBuffer errBuff = StringBuffer();
            errBuff.writeln('Error : Always use methods with expression body.');
            errBuff.writeln('');
            errBuff.writeln(
                'The method causing issue is $methodName at line ${location.lineNumber}\n');
            errBuff.writeln(
                '---> Line ${location.lineNumber} | ${member.toSource()} ');

            CWLogger.namedLog(
              errBuff.toString(),
              loggerColor: CWLoggerColor.red,
            );

            CWLogger.namedLog(
              "Fix: convert the above method to expression body and continue",
              loggerColor: CWLoggerColor.purple,
            );
            exit(1);
          }

          nodeHashMp[methodName] = ASNMethodNode(
            methodSignature: '$returnType $methodName$parameters',
            funcBody: funcBody,
            parameters: parameters ?? '',
            isBlockBody: isBlockBody,
            name: methodName,
            retunType: returnType,
          );
        }

        // Filter variables with allowed types
        if (member is FieldDeclaration) {
          String fieldType = member.fields.type?.toString() ?? '';
          if (_allowedTypes.contains(fieldType)) {
            for (VariableDeclaration variable in member.fields.variables) {
              String initialValue = variable.initializer != null
                  ? '${variable.initializer?.toSource()}'
                  : '';

              nodeHashMp[variable.name.toString()] = ASNVariableNode(
                declaredValue: initialValue,
                name: variable.name.toString(),
                retunType: fieldType,
              );
            }
          }
        }
      }
    }

    super.visitClassDeclaration(node);
  }
}

abstract class AppStringNode {
  final String name;
  final String retunType;

  AppStringNode({required this.name, required this.retunType});

  Map<dynamic, dynamic> toYamlDefinition();

  AppStringNode clearDefinition();
}

class ASNVariableNode extends AppStringNode {
  final String declaredValue;
  ASNVariableNode({
    required this.declaredValue,
    required super.name,
    required super.retunType,
  });

  @override
  Map<dynamic, dynamic> toYamlDefinition() {
    Map<dynamic, dynamic> yamlMap = {};
    yamlMap['type'] = "ASNVariableNode";
    yamlMap["name"] = name;
    yamlMap["returnType"] = retunType;
    return yamlMap;
  }

  @override
  ASNVariableNode clearDefinition() {
    return ASNVariableNode(
      declaredValue: "-",
      name: name,
      retunType: retunType,
    );
  }
}

class ASNMethodNode extends AppStringNode {
  final String methodSignature;
  final String funcBody;
  final String parameters;
  final bool isBlockBody;
  ASNMethodNode({
    required this.methodSignature,
    required this.funcBody,
    required this.parameters,
    required this.isBlockBody,
    required super.name,
    required super.retunType,
  });

  @override
  Map<dynamic, dynamic> toYamlDefinition() {
    Map<dynamic, dynamic> yamlMap = {};
    yamlMap['type'] = "ASNMethodNode";
    yamlMap["parameters"] = parameters;
    yamlMap["name"] = name;
    yamlMap["returnType"] = retunType;
    yamlMap["methodSignature"] = methodSignature;
    return yamlMap;
  }

  @override
  ASNMethodNode clearDefinition() {
    return ASNMethodNode(
      methodSignature: methodSignature,
      funcBody: "-",
      parameters: parameters,
      isBlockBody: isBlockBody,
      name: name,
      retunType: retunType,
    );
  }
}

class AppStringContext {
  final String defaultLanguageName;
  final String defaultLanguageCode;
  final Map<String, AppStringNode> nodeHashMap;

  AppStringContext({
    required this.defaultLanguageName,
    required this.defaultLanguageCode,
    required this.nodeHashMap,
  });

  factory AppStringContext.fromNodeHashMap({
    required Map<String, AppStringNode> nodeHashMap,
    required String Function(String input) stringSanitizer,
  }) {
    String defaultLanguageName = _extractVariableValue(
      key: 'defaultLanugageName',
      nullHandlerVal: 'English',
      nodeHashMap: nodeHashMap,
      stringSanitizer: stringSanitizer,
    );

    String defaultLanguageCode = _extractVariableValue(
      key: 'defaultLanguageCode',
      nullHandlerVal: 'en',
      nodeHashMap: nodeHashMap,
      stringSanitizer: stringSanitizer,
    );

    nodeHashMap.remove('defaultLanugageName');
    nodeHashMap.remove('defaultLanguageCode');

    return AppStringContext(
      defaultLanguageName: defaultLanguageName,
      defaultLanguageCode: defaultLanguageCode,
      nodeHashMap: nodeHashMap,
    );
  }

  static String _extractVariableValue({
    required String key,
    required String nullHandlerVal,
    required Map<String, AppStringNode> nodeHashMap,
    required String Function(String input) stringSanitizer,
  }) {
    if (nodeHashMap.containsKey(key) && nodeHashMap[key] is ASNVariableNode) {
      return stringSanitizer(
          (nodeHashMap[key] as ASNVariableNode).declaredValue);
    }
    return nullHandlerVal;
  }
}

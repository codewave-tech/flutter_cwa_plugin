part of mlg_command;

extension AppTranslationAnaluyzer on ArchBuddyMLG {
  Future<List<AppStringContext>?> analyzeAppTranlationFiles(String path) async {
    Directory generatedFilesDir = Directory(path);
    if (!generatedFilesDir.existsSync()) return null;

    CliSpin loader = CliSpin(
      text: "Checking for app_translation files in $path",
    ).start();

    List<File> appTranslationFiles =
        generatedFilesDir.listSync().map((e) => File(e.path)).toList();
    List<AppStringContext> languagesContext = [];

    for (int idx = 0; idx < appTranslationFiles.length; idx++) {
      final RegExp pattern = RegExp(r'app_localization_([a-z]{2})\.dart');
      String fileName = appTranslationFiles[idx].path.split('/').last;
      RegExpMatch? match = pattern.firstMatch(fileName);
      if (match != null) {
        // CWLogger.namedLog('Found $fileName', loggerColor: CWLoggerColor.green);
        String fileContent = appTranslationFiles[idx].readAsStringSync();

        var result = parseString(
          content: fileContent,
          featureSet: FeatureSet.latestLanguageVersion(),
        );

        Map<String, AppStringNode> nodeHashMp = {};

        LineInfo lineInfo = result.lineInfo;
        result.unit.visitChildren(AppTranslationsClassVisitor(
          nodeHashMp: nodeHashMp,
          lineInfo: lineInfo,
          langaugeCode: match.group(1) ?? 'en',
        ));

        languagesContext.add(
          AppStringContext.fromNodeHashMap(
            nodeHashMap: nodeHashMp,
            stringSanitizer: (str) => str,
          ),
        );
      }
    }

    if (languagesContext.isEmpty) {
      loader.info("No Translations found in the project");
    } else {
      loader.success(
          "Found : ${languagesContext.map((e) => e.defaultLanguageName)} ");
    }

    return languagesContext;
  }
}

class AppTranslationsClassVisitor extends RecursiveAstVisitor<void> {
  final LineInfo lineInfo;
  final Map<String, AppStringNode> nodeHashMp;
  final String langaugeCode;
  final List<String> _allowedTypes = ['String', 'int', 'double'];

  AppTranslationsClassVisitor({
    required this.nodeHashMp,
    required this.lineInfo,
    required this.langaugeCode,
  });

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.name.toString().contains('AppLocalization')) {
      nodeHashMp['defaultLanugageName'] = ASNVariableNode(
        declaredValue: node.name.toString().replaceAll('AppLocalization', ''),
        name: 'defaultLanugageName',
        retunType: 'String',
      );

      nodeHashMp['defaultLanguageCode'] = ASNVariableNode(
        declaredValue: langaugeCode,
        name: 'defaultLanguageCode',
        retunType: 'String',
      );

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

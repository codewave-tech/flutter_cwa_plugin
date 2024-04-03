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

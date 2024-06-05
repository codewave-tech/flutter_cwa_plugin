part of mlg_command;

extension AppLocalizationFileGenerator on ArchBuddyMLG {
  Future<void> generateAppLocalizationFile({
    required Map<String, AnalyzedLangugaeData> langData,
    required AppStringContext appStringContext,
    required String generationFolder,
  }) async {
    CWLogger.namedLog('Files will be generated at $generationFolder');

    CWLogger.i.progress('Generating Core Classes');
    String coreCodePath = await _generateCoreCode(
      langData: langData,
      appStringContext: appStringContext,
      generationFolder: generationFolder,
    );

    CWLogger.namedLog(
      "Genrated Core code succefully at $coreCodePath",
      loggerColor: CWLoggerColor.green,
    );

    await generateLanguageFiles(
      langData: langData,
      appStringContext: appStringContext,
      generationFolder: generationFolder,
    );

    CWLogger.i.progress('Formatting files');
    await Process.run('dart', ['format', generationFolder]);

    CWLogger.namedLog(
        'The localization files have been generated successfully!! Uncomment the method of(BuildContext context) in app_strings file.');
  }

  Future<void> generateLanguageFiles({
    required Map<String, AnalyzedLangugaeData> langData,
    required AppStringContext appStringContext,
    required String generationFolder,
  }) async {
    langData.forEach((key, value) {
      StringBuffer stringBuffer = StringBuffer();
      stringBuffer.writeln("import 'app_localization.dart';");
      stringBuffer.writeln(
          'class AppLocalization${value.languageName} extends AppLocalization {');
      stringBuffer.writeln(
          "AppLocalization${value.languageName}([String locale = '${value.languageCode}']) : super(locale);");
      value.varNameToContentMap.forEach((k, v) {
        if (!appStringContext.nodeHashMap.containsKey(k)) {
          CodeScout.logError("Didn't found $k in $key");
          return;
        }

        AppStringNode node = appStringContext.nodeHashMap[k]!;
        if (node is ASNMethodNode) {
          stringBuffer.writeln('\n@override');
          stringBuffer.writeln(
              '${node.retunType} ${node.name}${node.parameters} => \'$v\';');
        }

        if (node is ASNVariableNode) {
          stringBuffer.writeln('\n@override');
          stringBuffer.writeln('${node.retunType} get ${node.name} => \'$v\';');
        }
      });
      stringBuffer.writeln('}');
      File file =
          File('$generationFolder/app_localization_${value.languageCode}.dart');
      CWLogger.i.progress(
        'Creating ${value.languageName} translation file at $generationFolder/app_localization_${value.languageCode}.dart',
      );
      file.createSync();
      file.writeAsStringSync(stringBuffer.toString());

      CWLogger.namedLog(
        '${value.languageName} translations genrated successfully at $generationFolder/app_localization_${value.languageCode}.dart',
        loggerColor: CWLoggerColor.green,
      );
    });
  }

  Future<String> _generateCoreCode({
    required Map<String, AnalyzedLangugaeData> langData,
    required AppStringContext appStringContext,
    required String generationFolder,
  }) async {
    StringBuffer coreCodeBuff = StringBuffer();

    _coreImports(
      langData: langData,
      codeBuff: coreCodeBuff,
    );

    _generateAppLocalizationClass(
      langData: langData,
      appStringContext: appStringContext,
      codeBuff: coreCodeBuff,
    );

    _generateDeleagtes(
      langData: langData,
      appStringContext: appStringContext,
      codeBuff: coreCodeBuff,
    );

    FileService.ensureDirectoryExists(
        '$generationFolder/app_localization.dart');

    File('$generationFolder/app_localization.dart')
      ..createSync()
      ..writeAsStringSync(coreCodeBuff.toString());
    return "$generationFolder/app_localization.dart";
  }

  void _coreImports({
    required Map<String, AnalyzedLangugaeData> langData,
    required StringBuffer codeBuff,
  }) {
    langData.forEach((key, value) {
      codeBuff.writeln(
        "import 'app_localization_$key.dart';",
      );
    });

    codeBuff.writeln('''
  import 'package:flutter/foundation.dart' show FlutterError, SynchronousFuture;
  import 'package:flutter/material.dart' show Locale, LocalizationsDelegate;
  import 'package:flutter_localizations/flutter_localizations.dart'
    show
        GlobalMaterialLocalizations,
        GlobalCupertinoLocalizations,
        GlobalWidgetsLocalizations;
  ''');
  }

  void _generateAppLocalizationClass({
    required Map<String, AnalyzedLangugaeData> langData,
    required AppStringContext appStringContext,
    required StringBuffer codeBuff,
  }) {
    codeBuff.writeln('''
      abstract class AppLocalization {
      final String locale;

      AppLocalization(this.locale);

      static const LocalizationsDelegate<AppLocalization> delegate =
          _AppLocalizationsDelegate();

      static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
          <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

      static List<Locale> get supportedLocales =>
          (delegate as _AppLocalizationsDelegate)
              .supportedLocales
              .map((e) => Locale(e))
              .toList();

      static Language _activeLangugae = Language.${appStringContext.defaultLanguageName.toLowerCase()};

      static void updateLanguage(Language language) {
        if (_activeLangugae == language) return;
        _activeLangugae = language;
      }

      static Locale get currentLanguage {
        return Locale(_activeLangugae.getCode());
      }
    ''');
    appStringContext.nodeHashMap.forEach((key, value) {
      if (value is ASNMethodNode) {
        ASNMethodNode node = value;
        codeBuff.writeln('${node.methodSignature};');
      }

      if (value is ASNVariableNode) {
        ASNVariableNode node = value;
        codeBuff.writeln("${node.retunType} get ${node.name};");
      }
    });
    codeBuff.writeln('}');
  }

  void _generateDeleagtes({
    required Map<String, AnalyzedLangugaeData> langData,
    required AppStringContext appStringContext,
    required StringBuffer codeBuff,
  }) {
    codeBuff.writeln('''
    class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalization> {
    const _AppLocalizationsDelegate();

      @override
      Future<AppLocalization> load(Locale locale) {
        return SynchronousFuture<AppLocalization>(lookupAppLocalizations(locale));
      }

      List<String> get supportedLocales => ${langData.keys.map((e) => "'$e'").toList()};

      @override
      bool isSupported(Locale locale) =>
          supportedLocales.contains(locale.languageCode);

      @override
      bool shouldReload(_AppLocalizationsDelegate old) => false;
    }
    ''');

    codeBuff.writeln('AppLocalization lookupAppLocalizations(Locale locale) {');
    codeBuff.writeln('  // Lookup logic when only language code is specified.');
    codeBuff.writeln('  switch (locale.languageCode) {');
    langData.forEach((key, value) {
      codeBuff.writeln(' case "$key":');
      codeBuff.writeln('return AppLocalization${value.languageName}();');
    });
    codeBuff.writeln('''
 }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "\$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue ',
  );
  }
  ''');

    codeBuff.writeln('enum Language {');
    List<AnalyzedLangugaeData> analyzedArr = langData.values.toList();
    for (int idx = 0; idx < analyzedArr.length; idx++) {
      codeBuff.writeln(
          '${analyzedArr[idx].languageName.toLowerCase()} ${idx == analyzedArr.length - 1 ? ';' : ","}');
    }

    codeBuff.writeln(
        'static Language getLanguageFromCode({required String code}) {');
    codeBuff.writeln('switch (code) {');
    for (int idx = 0; idx < analyzedArr.length; idx++) {
      codeBuff.writeln('case "${analyzedArr[idx].languageCode}" :');
      codeBuff.writeln(
          'return Language.${analyzedArr[idx].languageName.toLowerCase()};');
    }
    codeBuff.writeln('}');
    codeBuff.writeln(
        'return Language.${appStringContext.defaultLanguageName.toLowerCase()};');
    codeBuff.writeln('}');

    codeBuff.writeln(' String getCode() {');
    codeBuff.writeln('switch (this) {');
    for (int idx = 0; idx < analyzedArr.length; idx++) {
      codeBuff.writeln(
          'case Language.${analyzedArr[idx].languageName.toLowerCase()} :');
      codeBuff.writeln('return "${analyzedArr[idx].languageCode}";');
    }
    codeBuff.writeln('}}}');
  }
}

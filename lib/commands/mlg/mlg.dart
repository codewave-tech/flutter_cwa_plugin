library mlg_command;

import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:excel/excel.dart';
import 'package:flutter_cwa_plugin/config/plugin_config.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';

part 'generate_translation_xlsx.dart';
part 'analyze_translation_xlsx.dart';
part 'app_string_analyzer.dart';
part 'generate_app_localization_dart_files.dart';
part 'app_translations_analyzer.dart';

class ArchBuddyMLG extends Command {
  ArchBuddyMLG(super.args);

  @override
  String get description => "Manage app multilingual settings.";

  String varHeaderName = 'Varibale/Method Name';
  String paramHeaderName = 'Parameters';

  @override
  Future<void> run() async {
    CWLogger.namedLog('Codewave Multilingual tool : ');
    Menu menu1 = Menu([
      'Generate Excel file',
      'Analyze Excel file and enable localization in the project'
    ]);

    int idx1;
    switch (FlutterPluginConfig.i.pluginEnvironment) {
      case PluginEnvironment.dev:
        idx1 = 1;
      case PluginEnvironment.prod:
        idx1 = menu1.choose().index;
    }

    if (idx1 == 0) {
      AppStringContext appStringContext = await analyzeAppStringFile(
        '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10nAppStringPath}',
      );

      List<AppStringContext>? languagesContext =
          await analyzeAppTranlationFiles(
        '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10ngeneratedPath}',
      );

      await generateExcel(appStringContext, languagesContext);

      exit(0);
    }

    Menu menu2 = Menu([
      'Use Google sheet URL',
      'Access the local excel file (codewave_translation_${RuntimeConfig().dependencyManager.name}.xlsx)'
    ]);

    int idx2;

    switch (FlutterPluginConfig.i.pluginEnvironment) {
      case PluginEnvironment.dev:
        idx2 = 2;
      case PluginEnvironment.prod:
        idx2 = menu2.choose().index;
    }

    if (idx2 == 0) {
      CWLogger.i.stdout('Please enter the Google sheet URL :');
      String? response = stdin.readLineSync();
      if (response == null) exit(2);
      String fileId = extractFileId(response);
      CWLogger.i.progress('Downloading Google sheet');
      await GoogleService.downloadSheetAsExcel(
        fileId,
        '${RuntimeConfig().commandExecutionPath}/codewave_translation_${RuntimeConfig().dependencyManager.name}.xlsx',
      );
    }

    Map<String, AnalyzedLangugaeData> langData = analyzeExcelFile(
      '${RuntimeConfig().commandExecutionPath}/codewave_translation_${RuntimeConfig().dependencyManager.name}.xlsx',
    );

    AppStringContext appStringContext = await analyzeAppStringFile(
        '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10nAppStringPath}');

    await generateAppLocalizationFile(
      langData: langData,
      appStringContext: appStringContext,
      generationFolder:
          '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10ngeneratedPath}',
    );

    exit(0);
  }

  static String extractFileId(String url) {
    var regExp = RegExp(r"/spreadsheets/d/([a-zA-Z0-9-_]+)");
    var match = regExp.firstMatch(url);
    String? fileId = match?.group(1);
    if (fileId == null) {
      CWLogger.i.stderr('Seems like the URL is wrong!, please try again.');
      exit(2);
    }
    return fileId;
  }
}

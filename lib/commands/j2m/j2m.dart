import 'dart:convert';
import 'dart:io';

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/config/plugin_config.dart';

import 'j2m_converter.dart';

class ArchBuddyJ2M extends Command {
  ArchBuddyJ2M(super.args);

  @override
  String get description => "Generate model for the provided json easily.";

  static final String apxJsonPath = 'json-path';

  @override
  Future<void> run() async {
    ArgsProcessor argsProcessor = ArgsProcessor(args);

    argsProcessor.process(
      index: 1,
      processedName: apxJsonPath,
    );

    String? path = argsProcessor.check(apxJsonPath);

    if (path == null) {
      CWLogger.inLinePrint("Path to your json file :");
      path = stdin.readLineSync();
    }

    if (path == null || path.isEmpty) {
      CWLogger.namedLog(
        'Invalid path provided',
        loggerColor: CWLoggerColor.red,
      );
      exit(2);
    }
    if (FlutterPluginConfig.i.pluginEnvironment != PluginEnvironment.dev) {
      CWLogger.inLinePrint("Confirm path : $path? (y/n)");
      if (stdin.readLineSync()?.toLowerCase() != 'y') exit(1);
    }

    File jsonFile = File(path);

    if (!jsonFile.existsSync()) {
      CWLogger.namedLog("File doesn't exist");
    }
    Map<String, dynamic> mp;

    try {
      mp = jsonDecode(jsonFile.readAsStringSync());
    } catch (e) {
      CWLogger.i.trace(e.toString());
      CWLogger.namedLog(
        "Erorr occured while parsing the json file",
        loggerColor: CWLoggerColor.red,
      );
      exit(2);
    }

    String? modelName;
    if (FlutterPluginConfig.i.pluginEnvironment == PluginEnvironment.dev) {
      modelName = 'DebugModel';
    }

    if (modelName == null) {
      do {
        CWLogger.inLinePrint("Enter a valid model name : ");
        modelName = stdin.readLineSync();
      } while (modelName == null || modelName.isEmpty);
    }

    J2mConverter j2mConverter = J2mConverter();
    String jsonModel = j2mConverter.generateModel(mp, modelName);

    jsonFile.writeAsStringSync(jsonModel);

    CWLogger.namedLog(
      "$modelName created successfully at ${jsonFile.path}",
      loggerColor: CWLoggerColor.green,
    );
    Process.runSync('dart', ['format', jsonFile.path.normalizedPath]);
  }
}

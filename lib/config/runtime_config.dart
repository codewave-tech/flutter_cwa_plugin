import 'dart:io';

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/config/plugin_config.dart';
import 'package:flutter_cwa_plugin/utils/framework_utils.dart';
import 'package:pubspec/pubspec.dart';

class RuntimeConfig extends RTC<PubSpec> {
  static final RuntimeConfig _runtimeConfig = RuntimeConfig._i();

  RuntimeConfig._i();

  factory RuntimeConfig() => _runtimeConfig;

  static final String l10nPath = 'lib/core/l10n';
  static final String l10ngeneratedPath = 'lib/core/l10n/generated';
  static final String l10nAppStringPath = 'lib/core/l10n/app_strings.dart';
  static final String libraryPath = 'lib/libraries';
  static final String featureLocation = 'lib/features';

  @override
  Future<void> initialize() async {
    switch (FlutterPluginConfig.i.pluginEnvironment) {
      case PluginEnvironment.dev:
        commandExecutionPath = '/Users/codewave/Desktop/projects/simcorner';
        break;
      case PluginEnvironment.prod:
        commandExecutionPath = Directory.current.path;
        break;
    }

    try {
      dependencyManager =
          await PubSpec.loadFile('$commandExecutionPath/pubspec.yaml');

      displayStartupBanner();
    } catch (e) {
      CWLogger.namedLog(
        "Failed to parse project's pubspec!!",
        loggerColor: CWLoggerColor.red,
      );
      CWLogger.i.trace(e.toString());
      // exit(0);
    }
  }

  @override
  void displayStartupBanner() {
    // Assuming 'pubspec' is an instance of PubSpec containing the parsed pubspec.yaml data
    String cliToolName =
        "Codewave Accelerator"; // Customize with your actual CLI tool name
    String projectName = dependencyManager.name ?? "codewave project";
    String projectVersion = dependencyManager.version.toString();
    String projectDescription =
        dependencyManager.description ?? "No description provided.";

    CWLogger.namedLog("Welcome to $cliToolName!");
    CWLogger.namedLog("Running on Flutter project: $projectName");
    CWLogger.namedLog("Version: $projectVersion");
    CWLogger.namedLog("Description: $projectDescription\n");
    CWLogger.namedLog("Initializing...\n");
  }
}

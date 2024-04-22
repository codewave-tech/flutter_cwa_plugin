import 'dart:io';

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/config/plugin_config.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';
import 'package:flutter_cwa_plugin/model/specification.dart';

class ArchBuddyAddFeature extends Command {
  ArchBuddyAddFeature(super.args);

  @override
  String get description => "";

  @override
  Future<void> run() async {
    CWLogger.i.progress("Looking for available features");

    List<String> dirs = await GitService.fetchDirectories(
      FlutterPluginConfig.i.pilotRepoProjectID,
      RuntimeConfig.featureLocation,
      TokenService().accessToken!,
    );

    if (dirs.isEmpty) {
      CWLogger.namedLog(
        'No Features Found!',
        loggerColor: CWLoggerColor.yellow,
      );
      exit(1);
    }

    CWLogger.i.stdout("Please select the feature you want to use");
    Menu featureMenu = Menu(dirs);

    int idx;
    switch (FlutterPluginConfig.i.pluginEnvironment) {
      case PluginEnvironment.dev:
        idx = 0;
      case PluginEnvironment.prod:
        idx = featureMenu.choose().index;
    }

    CWLogger.i.progress('Adding ${dirs[idx]} to the project');

    await GitService.downloadDirectoryContents(
      projectId: FlutterPluginConfig.i.pilotRepoProjectID,
      branch: FlutterPluginConfig.i.pilotRepoReferredBranch,
      directoryPath: '${RuntimeConfig.featureLocation}/${dirs[idx]}',
      downloadPathBase: RuntimeConfig().commandExecutionPath,
      accessToken: TokenService().accessToken!,
    );

    await FeatureSpecificationYaml.adaptSpecifications(
      specsfile:
          '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.featureLocation}/${dirs[idx]}/${SpecificationYamlImpl.fileName}',
      args: args,
    );
  }
}

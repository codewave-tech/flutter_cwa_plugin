import 'dart:io';

import 'package:cli_spin/cli_spin.dart';
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

    CWLogger.i.stdout("Please select the feature you want to use :");
    Menu featureMenu = Menu(dirs);

    int idx = featureMenu.choose().index;

    await _addFeature(dirs[idx]);

    await FeatureSpecificationYaml.adaptSpecifications(
      specsfile:
          '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.featureLocation}/${dirs[idx]}/${SpecificationYamlImpl.fileName}',
      args: args,
    );
  }

  Future<void> _addFeature(String featureName) async {
    CliSpin featureLoader =
        CliSpin(text: "Adding $featureName to the project").start();

    try {
      await GitService.downloadDirectoryContents(
        projectId: FlutterPluginConfig.i.pilotRepoProjectID,
        branch: FlutterPluginConfig.i.pilotRepoReferredBranch,
        directoryPath: '${RuntimeConfig.featureLocation}/$featureName',
        downloadPathBase: RuntimeConfig().commandExecutionPath,
        accessToken: TokenService().accessToken!,
      );
      featureLoader.success();
    } catch (e) {
      featureLoader.fail();
    }
  }
}

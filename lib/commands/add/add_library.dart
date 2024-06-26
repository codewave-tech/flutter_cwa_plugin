import 'dart:io';

import 'package:cli_spin/cli_spin.dart';
import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/config/plugin_config.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';
import 'package:flutter_cwa_plugin/model/specification.dart';

class ArchBuddyAddLibrary extends Command {
  ArchBuddyAddLibrary(super.args);

  @override
  String get description => "";

  @override
  Future<void> run() async {
    CWLogger.i.progress("Looking for available libraries");

    List<String> dirs = await GitService.fetchDirectories(
      FlutterPluginConfig.i.pilotRepoProjectID,
      RuntimeConfig.libraryPath,
      TokenService().accessToken!,
    );

    if (dirs.isEmpty) {
      CWLogger.namedLog(
        'No Libraries Found!',
        loggerColor: CWLoggerColor.yellow,
      );
      exit(1);
    }

    CWLogger.i.stdout("Please select the library you want to use");
    Menu featureMenu = Menu(dirs);

    int idx = featureMenu.choose().index;

    await addLibrary(dirs[idx]);

    await FeatureSpecificationYaml.adaptSpecifications(
      specsfile:
          '${RuntimeConfig.libraryPath}/${dirs[idx]}/${SpecificationYamlImpl.fileName}',
      args: args,
    );
  }

  static Future<void> addLibrary(String libraryName) async {
    CliSpin cliSpin =
        CliSpin(text: "Adding $libraryName to the project").start();

    try {
      await GitService.downloadDirectoryContents(
        projectId: FlutterPluginConfig.i.pilotRepoProjectID,
        branch: FlutterPluginConfig.i.pilotRepoReferredBranch,
        directoryPath: '${RuntimeConfig.libraryPath}/$libraryName',
        downloadPathBase: RuntimeConfig().commandExecutionPath,
        accessToken: TokenService().accessToken!,
        isProd:
            FlutterPluginConfig.i.pluginEnvironment == PluginEnvironment.prod,
      );
      cliSpin.success("$libraryName added successfully");
    } catch (e) {
      cliSpin.fail(e.toString());
    }
  }
}

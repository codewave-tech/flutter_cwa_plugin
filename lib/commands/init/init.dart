import 'dart:io';

import 'package:cli_spin/cli_spin.dart';
import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/config/plugin_config.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';
import 'package:flutter_cwa_plugin/utils/framework_utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';

class ArchBuddyInit extends Command {
  ArchBuddyInit(super.args);

  @override
  String get description => "Set up standard or custom project architectures.";

  static String apxInitializationType = 'initialization-type';
  static String apxConfigFilePath = 'config-file-path';

  @override
  Future<void> run() async {
    ArgsProcessor argsProcessor = ArgsProcessor(args);

    argsProcessor
      ..process(
        index: 1,
        processedName: apxInitializationType,
        valid: [
          'standard',
          'custom',
        ],
      )
      ..process(
        index: 2,
        processedName: apxConfigFilePath,
      );

    int? idx = argsProcessor.check(apxInitializationType);

    if (idx == null) {
      CWLogger.i.stdout("Select init type:");
      Menu menu = Menu([
        'Use standard predefined architectures',
        'Use custom conifguration file',
      ]);
      idx = menu.choose().index;
    }

    if (idx == 0) {
      List<String>? branches = await GitService.getGitLabBranches(
        FlutterPluginConfig.i.archManagerProjectID,
        TokenService().accessToken!,
      );

      if (branches == null) {
        CWLogger.namedLog(
          "Error occured while looking for available architectures",
          loggerColor: CWLoggerColor.red,
        );
        exit(1);
      }

      CWLogger.i.stdout("Select architecture:");
      Menu menu = Menu(branches);
      int branchIdx = menu.choose().index;

      CliSpin loader = CliSpin(
              text:
                  "Adapting architecture ${branches[branchIdx]} in the project")
          .start();

      String? archSpecsContent = await GitService.getGitLabFileContent(
        projectId: FlutterPluginConfig.i.archManagerProjectID,
        filePath: '__arch_specs.yaml',
        branch: branches[branchIdx],
        token: TokenService().accessToken!,
      );

      if (archSpecsContent == null) {
        loader.fail(
            "Unable to analyze the specification of the selected architecture");
        exit(1);
      }

      Map<dynamic, dynamic> archSpecsMap =
          YamlService.parseYamlContent(archSpecsContent);

      String entryPoint = archSpecsMap['entrypoint'];

      await GitService.downloadDirectoryContents(
        projectId: FlutterPluginConfig.i.archManagerProjectID,
        branch: branches[branchIdx],
        directoryPath: entryPoint,
        downloadPathBase: RuntimeConfig().commandExecutionPath,
        accessToken: TokenService().accessToken!,
        isProd:
            FlutterPluginConfig.i.pluginEnvironment == PluginEnvironment.prod,
      );

      File tmpPubSpec =
          File("${RuntimeConfig().commandExecutionPath}/.tmp_pubspec.yaml");
      tmpPubSpec.createSync();

      String? archPubspecContent = await GitService.getGitLabFileContent(
        projectId: FlutterPluginConfig.i.archManagerProjectID,
        filePath: 'pubspec.yaml',
        branch: branches[branchIdx],
        token: TokenService().accessToken!,
      );

      if (archPubspecContent == null) {
        loader.fail("Failed to add required dependencies");
        exit(1);
      }

      tmpPubSpec.writeAsStringSync(archPubspecContent);

      PubSpec pubSpec = await YamlService.loadPubspec('.tmp_pubspec.yaml');
      await FrameworkUtils.addPubspecDependencies(
        dependencies: pubSpec.dependencies,
      );

      await FrameworkUtils.saveAndPubGet();

      loader.success("Project now follows the selected architecture");

      return;
    }

    String? filePath = argsProcessor.check(ArchBuddyInit.apxConfigFilePath);

    if (filePath == null) {
      CWLogger.inLinePrint("Enter the path to config file");
      filePath = stdin.readLineSync();
    }

    CWLogger.i.progress("Migrating the project based on custom Architecture..");
    await ArchTree.createStructureFromJson(
      File(filePath!).readAsStringSync(),
      '.',
    );

    await FrameworkUtils.addPubspecDependencies(dependencies: {
      'provider': HostedReference(VersionConstraint.parse('^6.1.1')),
      'go_router': HostedReference(VersionConstraint.parse('^13.2.0')),
      'cw_core': GitReference(
        'git@gitlab.com-codewave:codewave-technologies/codewave-flutter-core.git',
        'main',
      ),
      'flutter_wiretap': GitReference(
        'git@gitlab.com-codewave:codewave-technologies/flutter-wiretap.git',
        'main',
      )
    });

    CWLogger.namedLog(
      "Completed Successfully!!",
    );
  }
}

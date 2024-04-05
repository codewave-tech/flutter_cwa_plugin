import 'dart:io';

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';
import 'package:flutter_cwa_plugin/model/specification.dart';

class ArchBuddyCreateFeature extends Command {
  ArchBuddyCreateFeature(super.args);

  final List<String> folders = ['controllers', 'view', 'logic'];

  @override
  String get description => "";

  @override
  Future<void> run({String? featureName}) async {
    if (featureName == null) {
      do {
        CWLogger.inLinePrint('Feature Name :');
        featureName = stdin.readLineSync();
      } while (featureName == null);
    }

    String name = _validateAndFormatName(featureName);
    Directory featureDirectory = Directory(
      '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.featureLocation}',
    );
    featureDirectory.createSync();

    for (int idx = 0; idx < folders.length; idx++) {
      File('${featureDirectory.path}/$name/${folders[idx]}/.gitkeep')
          .createSync(
        recursive: true,
      );
    }

    saveyamlContent(
      name: name,
      path: "${featureDirectory.path}/$name/${SpecificationYamlImpl.fileName}",
    );
  }

  String _validateAndFormatName(String name) {
    // Trim leading and trailing spaces
    String formattedName = name.trim();

    // Remove any special characters except underscore, then replace spaces with underscores
    formattedName =
        formattedName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');

    // Convert to lowercase
    formattedName = formattedName.toLowerCase();

    return formattedName;
  }
}

void saveyamlContent({required String name, required String path}) {
  FeatureSpecificationYaml(
    name: name,
    version: "0.0.1",
    sdkConstraints:
        "${RuntimeConfig().dependencyManager.environment?.sdkConstraint}",
    harbor: RuntimeConfig().dependencyManager.name ?? "",
    dependencies: null,
  ).save(path);
}

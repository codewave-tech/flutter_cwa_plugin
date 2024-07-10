import 'dart:io' show Directory, Process;

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';
import 'package:pubspec/pubspec.dart';

class FrameworkUtils {
  static Future<void> addPubspecDependencies({
    required Map<String, DependencyReference> dependencies,
  }) async {
    RuntimeConfig().dependencyManager.dependencies.addAll(dependencies);
    print(RuntimeConfig().dependencyManager.dependencies);

    CWLogger.i.trace(RuntimeConfig().dependencyManager.toJson().toString());
  }

  static Future<void> addPubSpecAssets({
    List<String>? assetPaths,
  }) async {
    if (assetPaths == null || assetPaths.isEmpty) return;

    Map<dynamic, dynamic>? currMap =
        RuntimeConfig().dependencyManager.unParsedYaml;

    if (currMap == null) return;

    // Create a deep copy of the map
    Map<dynamic, dynamic> newMap = deepCopyMap(currMap);

    if (!newMap.containsKey('flutter')) return;

    if ((newMap['flutter'] as Map).containsKey('assets')) {
      // Create a modifiable copy of the assets list
      List<dynamic> newList = List.from(newMap['flutter']['assets'] as List);

      newList.addAll(assetPaths);
      newMap['flutter']['assets'] = newList;
    } else {
      newMap['flutter']['assets'] = assetPaths;
    }

    RuntimeConfig().dependencyManager = RuntimeConfig().dependencyManager.copy(
          unParsedYaml: newMap,
        );

    YamlService.saveYamlFile(
      '${RuntimeConfig().commandExecutionPath}/pubspec.yaml',
      RuntimeConfig().dependencyManager.toJson(),
    );

    CWLogger.i.trace(RuntimeConfig().dependencyManager.toJson().toString());
  }

// Function to deep copy a map
  static Map<dynamic, dynamic> deepCopyMap(Map<dynamic, dynamic> original) {
    Map<dynamic, dynamic> copy = {};
    original.forEach((key, value) {
      if (value is Map) {
        copy[key] = deepCopyMap(value);
      } else if (value is List) {
        copy[key] = List.from(value);
      } else {
        copy[key] = value;
      }
    });
    return copy;
  }

  static Future<void> saveAndPubGet() async {
    await savePubspec();
    runPubGet();
  }

  static void runPubGet() {
    Process.runSync('flutter', ['pub', 'get']);
  }

  static Future<void> savePubspec() async {
    await RuntimeConfig()
        .dependencyManager
        .save(Directory(RuntimeConfig().commandExecutionPath));
  }
}

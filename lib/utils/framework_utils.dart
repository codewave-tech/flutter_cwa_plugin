import 'dart:io' show Directory, Process;

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';
import 'package:pubspec/pubspec.dart';

class FrameworkUtils {
  static Future<void> addPubspecDependencies({
    required Map<String, DependencyReference> dependencies,
  }) async {
    RuntimeConfig().dependencyManager.dependencies.addAll(dependencies);

    CWLogger.i.progress('Adding dependencies');
    CWLogger.i.trace(RuntimeConfig().dependencyManager.toJson().toString());
    await RuntimeConfig().dependencyManager.save(Directory.current);
    Process.runSync('flutter', ['pub', 'get']);
  }
}

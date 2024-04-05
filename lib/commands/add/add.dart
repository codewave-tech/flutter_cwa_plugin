import 'dart:io';

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/commands/add/add_feature.dart';
import 'package:flutter_cwa_plugin/commands/add/add_library.dart';
import 'package:flutter_cwa_plugin/config/plugin_config.dart';

class ArchBuddyAdd extends Command {
  ArchBuddyAdd(super.args);

  @override
  String get description =>
      "Add features, libraries, or utilities from our pilot repo.";

  @override
  Future<void> run() async {
    CWLogger.i.stdout('Please select :');
    Menu<String> menu = Menu([
      'Add a Feature',
      'Add a library',
      'Add Makefile - for web support',
    ]);

    int idx;

    switch (FlutterPluginConfig.i.pluginEnvironment) {
      case PluginEnvironment.dev:
        idx = 0;
        break;
      case PluginEnvironment.prod:
        idx = menu.choose().index;
        break;
    }

    switch (idx) {
      case 0:
        await ArchBuddyAddFeature(args).run();
      case 1:
        await ArchBuddyAddLibrary(args).run();
      default:
        exit(2);
    }
  }
}

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/commands/add/add.dart';

class FlutterPlugin extends Plugin {
  FlutterPlugin(super.args);

  @override
  Map<String, Command> get commands => {
        "add": ArchBuddyAdd(args),
      };

  @override
  void onInstall() {}

  @override
  void onUninstall() {}

  @override
  void pluginEntry() {}

  @override
  String get pluginName => 'flutter_cwa_plugin';
}

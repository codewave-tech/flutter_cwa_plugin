import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/commands/add/add.dart';
import 'package:flutter_cwa_plugin/commands/advanced/advanced.dart';
import 'package:flutter_cwa_plugin/commands/connect/connect.dart';
import 'package:flutter_cwa_plugin/commands/create/create.dart';
import 'package:flutter_cwa_plugin/commands/dynamize-theme/dynamize_theme.dart';
import 'package:flutter_cwa_plugin/commands/harbor/harbor.dart';
import 'package:flutter_cwa_plugin/commands/init/init.dart';
import 'package:flutter_cwa_plugin/commands/j2m/j2m.dart';
import 'package:flutter_cwa_plugin/commands/mlg/mlg.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';

class FlutterPlugin extends Plugin {
  FlutterPlugin(super.args);

  @override
  String get alias => 'flt';

  @override
  Map<String, Command> get commands => {
        "add": ArchBuddyAdd(args),
        "advanced": ArchBuddyAdvanced(args),
        "connect": ArchBuddyConnect(args),
        "create": ArchBuddyCreate(args),
        "dynamize-theme": ArchBuddyDynamizeTheme(args),
        "harbor": ArchBuddyHarbor(args),
        "init": ArchBuddyInit(args),
        "j2m": ArchBuddyJ2M(args),
        "mlg": ArchBuddyMLG(args),
      };

  @override
  void pluginEntry() async {
    super.pluginEntry();

    await RuntimeConfig().initialize();

    if (commands.containsKey(args[0])) {
      commands[args[0]]?.run();
    }
  }
}

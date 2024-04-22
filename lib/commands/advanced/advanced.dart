import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/commands/dynamize-theme/dynamize_theme.dart';
import 'package:flutter_cwa_plugin/commands/mlg/mlg.dart';

class ArchBuddyAdvanced extends Command {
  ArchBuddyAdvanced(super.args);

  @override
  String get description => "Access advanced features and configurations.";

  @override
  Future<void> run() async {
    Menu menu = Menu(
      [
        'Dynamic Theme Support',
        'Multilingual Support',
      ],
    );
    MenuResult result = menu.choose();
    if (result.index == 0) {
      await ArchBuddyDynamizeTheme(args).run();
    } else if (result.index == 1) {
      await ArchBuddyMLG(args).run();
    }
  }
}

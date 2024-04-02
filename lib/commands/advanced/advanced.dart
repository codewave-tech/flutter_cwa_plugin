import 'package:arch_buddy/commands/dynamize-theme/dynamize_theme.dart';
import 'package:arch_buddy/commands/mlg/mlg.dart';
import 'package:cwa_plugin_core/cwa_plugin_core.dart';

class ArchBuddyAdvanced extends Command {
  ArchBuddyAdvanced(super.args);

  @override
  Future<void> run() async {
    Menu<String> menu = Menu(
      [
        'Dynamic Theme Support',
        'Multilingual Support',
      ],
    );
    MenuResult<String> result = menu.choose();
    if (result.index == 0) {
      await ArchBuddyDynamizeTheme(args).run();
    } else if (result.index == 1) {
      await ArchBuddyMLG(args).run();
    }
  }
}

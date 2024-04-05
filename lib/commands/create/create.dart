import 'dart:io';

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/commands/create/create_feature.dart';

class ArchBuddyCreate extends Command {
  ArchBuddyCreate(super.args);

  @override
  String get description =>
      "Generate features or libraries with Harbor support.";

  String apxCreationType = 'creation-type';
  String apxCreationName = 'creation-name';

  @override
  Future<void> run() async {
    ArgsProcessor argsProcessor = ArgsProcessor(args);

    argsProcessor
      ..process(
        index: 1,
        processedName: apxCreationType,
        valid: ['feature', 'library'],
      )
      ..process(
        index: 2,
        processedName: apxCreationName,
      );

    int? idx = argsProcessor.check(apxCreationType);

    if (idx == null) {
      CWLogger.i.stdout('Please select :');
      Menu<String> menu = Menu([
        'Create Feature',
        'Create Library',
      ]);
      idx = menu.choose().index;
    }

    switch (idx) {
      case 0:
        await ArchBuddyCreateFeature(args).run(
          featureName: argsProcessor.check(
            apxCreationName,
          ),
        );
      case 1:
      // await ArchBuddyAddLibrary(args).run();
      default:
        exit(2);
    }
  }
}

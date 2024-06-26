import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/commands/mlg/mlg.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';
import 'package:flutter_cwa_plugin/model/specification.dart';
import 'package:pubspec/pubspec.dart';

class ArchBuddyHarbor extends Command {
  ArchBuddyHarbor(super.args);

  @override
  String get description => "Prepare features or libraries for release.";

  @override
  Future<void> run() async {
    // The path to your feature folder
    String featureFolderPath = "lib/features".normalizedPath;
    // '/Users/codewave/Desktop/projects/cli/cwa_pilot/lib/features';

    Directory featureFolder = Directory(featureFolderPath);

    // Check if the directory exists
    if (!await featureFolder.exists()) {
      CWLogger.namedLog(
        'Feature folder does not exist at the path: $featureFolderPath',
        loggerColor: CWLoggerColor.red,
      );
      return;
    }

    List<Directory> features =
        featureFolder.listSync().whereType<Directory>().toList();

    if (features.isEmpty) {
      CWLogger.namedLog(
        'No features found...!!!',
        loggerColor: CWLoggerColor.yellow,
      );
      exit(1);
    }

    CWLogger.namedLog("Select the feature you want to ship");

    Menu featureMenu =
        Menu(features.map((e) => e.path.split('/').last).toList());
    int idx = featureMenu.choose().index;
    // int idx = 0;

    featureFolderPath = features[idx].path;
    featureFolder = Directory(featureFolderPath);

    // List to hold all unique AppString variables
    final Set<String> appStringVariables = {};
    final Set<String> usedPackages = {};

    // Recursively search for .dart files and analyze them
    await for (final file in featureFolder.list(recursive: true)) {
      if (file.path.endsWith('.dart')) {
        await analyzeDartFile(file, appStringVariables);
        await extractDartImports(file, usedPackages);
      }
    }

    if (appStringVariables.isEmpty) {
      CWLogger.namedLog(
        "No AppStrings found in the feautre",
        loggerColor: CWLoggerColor.red,
      );
      exit(2);
    }

    ArchBuddyMLG archBuddyMLG = ArchBuddyMLG(args);
    String appStringPath = "./lib/core/l10n/app_strings.dart".normalizedPath;

    // "/Users/codewave/Desktop/projects/cli/cwa_pilot/lib/core/l10n/app_strings.dart";
    AppStringContext appStringContext =
        await archBuddyMLG.analyzeAppStringFile(appStringPath);

    String appTranslationsFilePath = "./lib/core/l10n/generated".normalizedPath;

    // "/Users/codewave/Desktop/projects/cli/cwa_pilot/lib/core/l10n/generated";

    List<AppStringContext>? appTranslationContexts =
        await archBuddyMLG.analyzeAppTranlationFiles(appTranslationsFilePath);

    SpeficificationDelegate speficificationDelegate =
        SpecificationYamlImpl.fromFeatureDirectory(featureFolderPath);

    FeatureSpecificationYaml featureSpecificationYaml =
        FeatureSpecificationYaml.fromSepcificationDelegate(
            speficificationDelegate);

    Map<String, DependencyReference>? dependencies = {};

    if (usedPackages.isNotEmpty) {
      for (int idx = 0; idx < usedPackages.length; idx++) {
        String pkg = usedPackages.elementAt(idx);
        if (RuntimeConfig().dependencyManager.dependencies.containsKey(pkg)) {
          dependencies[pkg] =
              RuntimeConfig().dependencyManager.dependencies[pkg]!;
        }
      }
    }

    FeatureSpecificationYaml file = featureSpecificationYaml.copyWith(
      appStringContext: appStringContext,
      appTranslationContexts: appTranslationContexts,
      usedNodes: appStringVariables.toList(),
      dependencies: dependencies,
    );

    file.save('$featureFolderPath/${SpecificationYamlImpl.fileName}');
  }

  // Analyze a single Dart file
  Future<void> analyzeDartFile(
      FileSystemEntity file, Set<String> appStringVariables) async {
    String code = await File(file.path).readAsString();

    appStringVariables.addAll(findUntranslatedStrings(code));

    appStringVariables.addAll(findtranslatedStrings(code));
  }

  Set<String> findUntranslatedStrings(String code) {
    RegExp regExp = RegExp(r'AppStrings\.ofUntranslated\(context\)\.(\w+)');
    Iterable<RegExpMatch> matches = regExp.allMatches(code);

    return matches.map((match) => match.group(1)!).toSet();
  }

  Set<String> findtranslatedStrings(String code) {
    RegExp regExp = RegExp(r'AppStrings\.of\(context\)\.(\w+)');
    Iterable<RegExpMatch> matches = regExp.allMatches(code);

    return matches.map((match) => match.group(1)!).toSet();
  }

  Future<void> extractDartImports(
      FileSystemEntity file, Set<String> usedPackages) async {
    if (file is Directory) return;
    String content = (file as File).readAsStringSync();
    ParseStringResult res = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    res.unit.visitChildren(ImportCollector(usedPackages: usedPackages));
  }
}

class ImportCollector extends RecursiveAstVisitor<void> {
  final Set<String> usedPackages;

  ImportCollector({required this.usedPackages});

  @override
  void visitImportDirective(ImportDirective node) {
    String? packageName = extractPackageName(node.uri.stringValue);
    if (packageName != null) {
      usedPackages.add(packageName);
    }

    super.visitImportDirective(node);
  }

  String? extractPackageName(String? input) {
    if (input == null || input.isEmpty) return null;
    RegExp pattern = RegExp(r'package:([^\/]+)\/');
    var match = pattern.firstMatch(input);
    return match?.group(1) ?? 'Package name not found';
  }
}

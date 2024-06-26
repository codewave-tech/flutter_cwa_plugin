import 'dart:io' show File;

import 'package:cli_spin/cli_spin.dart';
import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:flutter_cwa_plugin/commands/add/add_library.dart';
import 'package:flutter_cwa_plugin/commands/mlg/mlg.dart';
import 'package:flutter_cwa_plugin/config/plugin_config.dart';
import 'package:flutter_cwa_plugin/config/runtime_config.dart';
import 'package:flutter_cwa_plugin/utils/framework_utils.dart';
import 'package:pubspec/pubspec.dart';

class FeatureSpecificationYaml extends SpecificationYamlImpl {
  FeatureSpecificationYaml({
    required super.name,
    required super.version,
    required super.sdkConstraints,
    required super.harbor,
    required super.dependencies,
    super.appStringContext,
    super.appTranslationContexts,
    super.usedNodes,
    super.assetPaths,
    super.libraries,
  });

  @override
  FeatureSpecificationYaml copyWith({
    String? name,
    String? version,
    String? sdkConstraints,
    String? harbor,
    Map<String, DependencyReference>? dependencies,
    AppStringContext? appStringContext,
    List<AppStringContext>? appTranslationContexts,
    List<String>? usedNodes,
    List<String>? assetPaths,
    List<String>? libraries,
  }) {
    return FeatureSpecificationYaml(
      name: name ?? this.name,
      version: version ?? this.version,
      sdkConstraints: sdkConstraints ?? this.sdkConstraints,
      harbor: harbor ?? this.harbor,
      dependencies: dependencies ?? this.dependencies,
      appStringContext: appStringContext ?? this.appStringContext,
      appTranslationContexts:
          appTranslationContexts ?? this.appTranslationContexts,
      usedNodes: usedNodes ?? this.usedNodes,
      assetPaths: assetPaths ?? this.assetPaths,
      libraries: libraries ?? this.libraries,
    );
  }

  factory FeatureSpecificationYaml.fromSepcificationDelegate(
      SpeficificationDelegate speficificationDelegate) {
    return FeatureSpecificationYaml(
      name: speficificationDelegate.name,
      version: speficificationDelegate.version,
      sdkConstraints: speficificationDelegate.sdkConstraints,
      harbor: speficificationDelegate.harbor,
      dependencies: speficificationDelegate.dependencies,
      appStringContext: speficificationDelegate.appStringContext,
      appTranslationContexts: speficificationDelegate.appTranslationContexts,
      usedNodes: speficificationDelegate.usedNodes,
      assetPaths: speficificationDelegate.assetPaths,
      libraries: speficificationDelegate.libraries,
    );
  }

  static Future<void> adaptSpecifications({
    required String specsfile,
    required List<String> args,
  }) async {
    if (File(specsfile).existsSync()) {
      SpeficificationDelegate speficificationDelegate =
          SpecificationYamlImpl.parse(specsfile);

      Map<String, DependencyReference> requirements = {};

      FeatureSpecificationYaml featureSpecificationYaml =
          FeatureSpecificationYaml.fromSepcificationDelegate(
              speficificationDelegate);

      print(featureSpecificationYaml.libraries);

      featureSpecificationYaml.dependencies?.forEach((key, value) {
        requirements[key] = value;
      });

      ArchBuddyMLG archBuddyMLG = ArchBuddyMLG(args);
      AppStringContext appStringContext =
          await archBuddyMLG.analyzeAppStringFile(
        '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10nAppStringPath}',
      );

      List<AppStringContext>? appTranslationContexts =
          await archBuddyMLG.analyzeAppTranlationFiles(
        '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10ngeneratedPath}',
      );

      await _analyzedLanguageDataMapFromAppTransalation(
        appStringContext: appStringContext,
        appTranslationContexts: appTranslationContexts,
        featureSpecificationYaml: featureSpecificationYaml,
      );

      await addAssets(featureSpecificationYaml.assetPaths);

      for (int idx = 0;
          idx < (featureSpecificationYaml.libraries?.length ?? 0);
          idx++) {
        await ArchBuddyAddLibrary.addLibrary(
          featureSpecificationYaml.libraries![idx],
        );
      }

      CliSpin loader = CliSpin(text: "Adding dependencies").start();
      try {
        await FrameworkUtils.addPubspecDependencies(dependencies: requirements);

        await FrameworkUtils.saveAndPubGet();

        loader.success("Dependencies added successfully");
      } catch (e) {
        loader.fail(e.toString());
      }
    }
  }

  static Future<void> addAssets(List<String>? assetPaths) async {
    if (assetPaths == null || assetPaths.isEmpty) return;

    CliSpin loader = CliSpin(text: "Downloading assets").start();
    try {
      for (int idx = 0; idx < assetPaths.length; idx++) {
        await GitService.downloadDirectoryContents(
          projectId: FlutterPluginConfig.i.pilotRepoProjectID,
          branch: FlutterPluginConfig.i.pilotRepoReferredBranch,
          directoryPath: assetPaths[idx],
          downloadPathBase: RuntimeConfig().commandExecutionPath,
          accessToken: TokenService().accessToken!,
        );
      }

      FrameworkUtils.addPubSpecAssets(assetPaths: assetPaths);

      loader.success('Assets added successfully');
    } catch (e) {
      loader.fail(e.toString());
    }
  }

  static Future<void> _analyzedLanguageDataMapFromAppTransalation({
    required AppStringContext appStringContext,
    required List<AppStringContext>? appTranslationContexts,
    required FeatureSpecificationYaml featureSpecificationYaml,
  }) async {
    if (featureSpecificationYaml.appStringContext == null) return;
    CliSpin loader = CliSpin(text: "Injecting strings").start();
    try {
      // app string context injection
      String? featureDefaultLang =
          featureSpecificationYaml.appStringContext!.defaultLanguageCode;
      String? defaultLang = appStringContext.defaultLanguageCode;

      int? idx;

      bool hasMismatch = featureDefaultLang != defaultLang;

      // has default language mismatch
      if (hasMismatch) {
        // get the index of app string context with where the default language matches
        idx = _hasALangMatch(featureSpecificationYaml, defaultLang);
      }

      if (hasMismatch && idx != null) {
        _fillAppStringFile(
          featureSpecificationYaml.appTranslationContexts![idx],
          featureSpecificationYaml,
        );
      } else {
        _fillAppStringFile(
          featureSpecificationYaml.appStringContext!,
          featureSpecificationYaml,
          fillContent: !hasMismatch,
        );
      }

      appStringContext.nodeHashMap.addAll(
        featureSpecificationYaml.appStringContext?.nodeHashMap ?? {},
      );

      await _fillAppTranslationFiles(
        appStringContext: appStringContext,
        featureSpecificationYaml: featureSpecificationYaml,
      );

      loader.success('Strings injected successfully');
    } catch (e) {
      loader.fail(e.toString());
    }
  }

  static int? _hasALangMatch(
      FeatureSpecificationYaml featureSpecificationYaml, String defaultLang) {
    if (featureSpecificationYaml.appTranslationContexts != null) {
      for (int idx = 0;
          idx < featureSpecificationYaml.appTranslationContexts!.length;
          idx++) {
        if (defaultLang ==
            featureSpecificationYaml
                .appTranslationContexts?[idx].defaultLanguageCode) {
          return idx;
        }
      }
    }

    return null;
  }

  static void _fillAppStringFile(
    AppStringContext appStringContext,
    FeatureSpecificationYaml featureSpecificationYaml, {
    bool fillContent = true,
  }) {
    File appStringFile = File(
        "${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10nAppStringPath}");
    String appStringContent = appStringFile.readAsStringSync();
    int closeIdx = appStringContent.lastIndexOf('}');

    StringBuffer strBuff = StringBuffer();

    strBuff.writeln(appStringContent.substring(0, closeIdx));

    strBuff.writeln(
        "// THE STRINGS BELOW ARE INJECTED BY CWA FOR THE FEATURE ${featureSpecificationYaml.name} - VERSION ${featureSpecificationYaml.version}");
    appStringContext.nodeHashMap.forEach((key, value) {
      if (value is ASNMethodNode) {
        String val = fillContent ? value.funcBody : '-';
        strBuff.writeln(
          '${value.retunType} ${value.name}${value.parameters} => \'$val\';',
        );
      }

      if (value is ASNVariableNode) {
        String val = fillContent ? value.declaredValue : "-";
        strBuff.writeln('${value.retunType} ${value.name} = \'$val\';');
      }
    });

    strBuff.writeln(appStringContent.substring(closeIdx));

    appStringFile.writeAsStringSync(strBuff.toString());
  }

  static Future<void> _fillAppTranslationFiles({
    required FeatureSpecificationYaml featureSpecificationYaml,
    required AppStringContext appStringContext,
  }) async {
    if (featureSpecificationYaml.appTranslationContexts == null) return;

    List<AppStringContext>? languagesContext =
        await ArchBuddyMLG([]).analyzeAppTranlationFiles(
      '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10ngeneratedPath}',
    );

    if (languagesContext == null || languagesContext.isEmpty) return;

    for (int idx = 0; idx < languagesContext.length; idx++) {
      String langCode = languagesContext[idx].defaultLanguageCode;

      int? langIdx = _hasALangMatch(featureSpecificationYaml, langCode);

      if (langIdx != null) {
        _fillAppStringContext(
          languagesContext[idx],
          featureSpecificationYaml.appTranslationContexts![langIdx],
        );
      } else {
        _fillAppStringContext(
          languagesContext[idx],
          featureSpecificationYaml.appStringContext!,
          fillContent: false,
        );
      }
    }

    Map<String, AnalyzedLangugaeData> mp = {};
    for (int idx = 0; idx < languagesContext.length; idx++) {
      mp[languagesContext[idx].defaultLanguageCode] =
          AnalyzedLangugaeData.fromAppStringContext(languagesContext[idx]);
    }

    await ArchBuddyMLG([]).generateAppLocalizationFile(
      langData: mp,
      appStringContext: appStringContext,
      generationFolder:
          '${RuntimeConfig().commandExecutionPath}/${RuntimeConfig.l10ngeneratedPath}',
    );
  }

  static void _fillAppStringContext(
    AppStringContext appStringContext,
    AppStringContext featureAppStringContext, {
    bool fillContent = true,
  }) {
    featureAppStringContext.nodeHashMap.forEach((key, value) {
      appStringContext.nodeHashMap[key] =
          fillContent ? value : value.clearDefinition();
    });
  }
}

import 'package:cwa_plugin_core/cwa_plugin_core.dart';
import 'package:pub_semver/src/version.dart';

class FlutterPluginConfig extends PluginConfig {
  static final FlutterPluginConfig i = FlutterPluginConfig._i();

  FlutterPluginConfig._i();

  factory FlutterPluginConfig() => i;

  @override
  String get archManagerProjectID => '55849600';

  @override
  String get pilotRepoProjectID => '55596387';

  @override
  String get pilotRepoReferredBranch => 'main';

  @override
  PluginEnvironment get pluginEnvironment => PluginEnvironment.prod;

  @override
  Version get version => Version.parse("1.0.0");
}

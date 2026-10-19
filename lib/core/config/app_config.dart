/// Static app-wide configuration.
class AppConfig {
  AppConfig._();

  static const String appName = 'EmasKu';
  static const String apiBase = 'https://logam-mulia-api.iamutaki.workers.dev';
  static const String apiDocsUrl = '$apiBase/api/docs';
  static const String apiRepoUrl =
      'https://github.com/iamutaki/logam-mulia-api';

  /// Material type used as the default reference for portfolio valuation.
  static const String defaultMaterial = 'gold';
}

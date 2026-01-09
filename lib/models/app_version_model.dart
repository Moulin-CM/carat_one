class AppVersionModel {
  final String minRequiredVersion;
  final int minRequiredBuild;
  final String latestVersion;
  final int latestBuild;
  final bool forceUpdate;
  final String updateMessage;
  final String updateUrl;

  AppVersionModel({
    required this.minRequiredVersion,
    required this.minRequiredBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.forceUpdate,
    required this.updateMessage,
    required this.updateUrl,
  });

  factory AppVersionModel.fromJson(Map<dynamic, dynamic> json) {
    return AppVersionModel(
      minRequiredVersion: json['minRequiredVersion'] ?? '1.0.0',
      minRequiredBuild: json['minRequiredBuild'] ?? 1,
      latestVersion: json['latestVersion'] ?? '1.0.0',
      latestBuild: json['latestBuild'] ?? 1,
      forceUpdate: json['forceUpdate'] ?? false,
      updateMessage: json['updateMessage'] ?? 'A new version of the app is available. Please update to continue.',
      updateUrl: json['updateUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minRequiredVersion': minRequiredVersion,
      'minRequiredBuild': minRequiredBuild,
      'latestVersion': latestVersion,
      'latestBuild': latestBuild,
      'forceUpdate': forceUpdate,
      'updateMessage': updateMessage,
      'updateUrl': updateUrl,
    };
  }
}


//  repo_context.dart 
//  Created by JeoJay127 
//
import 'dart:io';
import 'github_model.dart';
import 'repo_config.dart';

extension GitHubReleasePlatformAsset on GitHubRelease {
  GitHubAsset? assetForCurrentPlatform() {
    for (final asset in assets) {
      final name = asset.name.toLowerCase();

      if (Platform.isMacOS &&
          (name.contains('macos') || name.endsWith('.dmg'))) {
        return asset;
      }

      if (Platform.isWindows &&
          (name.contains('windows') || name.endsWith('.exe'))) {
        return asset;
      }

      if (Platform.isLinux &&
          (name.contains('linux') || name.endsWith('.tar.xz'))) {
        return asset;
      }
    }
    return null;
  }
}

class RepoContext {
  final RepoConfig repoConfig;
  final GitHubRelease release;
  const RepoContext({required this.repoConfig, required this.release});
}

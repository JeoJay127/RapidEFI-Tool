//  github_model.dart
//  Created by JeoJay127
//
class GitHubRelease {
  final String tag;
  final String name;
  final String body;
  final DateTime publishedAt;
  final bool prerelease;
  final List<GitHubAsset> assets;

  GitHubRelease({
    required this.tag,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.prerelease,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) => GitHubRelease(
    tag: json['tag_name'] ?? '',
    name: json['name'] ?? '',
    body: json['body'] ?? '',
    prerelease: json['prerelease'] ?? false,
    publishedAt: DateTime.parse(json['published_at']).toLocal(),
    assets: (json['assets'] as List<dynamic>)
        .map((e) => GitHubAsset.fromJson(e))
        .toList(),
  );
}

class GitHubAsset {
  final String name;
  final String downloadUrl;
  final int size;

  GitHubAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  factory GitHubAsset.fromJson(Map<String, dynamic> json) => GitHubAsset(
    name: json['name'],
    downloadUrl: json['browser_download_url'],
    size: json['size'],
  );
}

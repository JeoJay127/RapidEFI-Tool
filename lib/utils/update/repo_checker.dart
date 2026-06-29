//  repo_checker.dart 
//  Created by JeoJay127 
//

import 'github_api_client.dart';
import 'github_model.dart';
import 'repo_config.dart';

class RepoChecker {
  final GitHubApiClient api = GitHubApiClient();
  RepoChecker();

  Future<List<GitHubRelease>?> checkReleases({
    required RepoConfig config,
  }) async {
    final json = await api.getReleases(owner: config.owner, repo: config.repo);
    if (json == null) return null;
    final releases = json.map((e) => GitHubRelease.fromJson(e)).toList();
    return releases;
  }

  Future<GitHubRelease?> checkLatestRelease({
    required RepoConfig config,
    required String currentVersion,
    Function(dynamic error)? onError,
  }) async {
    final json = await api.getLatestRelease(
      owner: config.owner,
      repo: config.repo,
      onError: onError,
    );

    if (json == null) return null;

    final latest = GitHubRelease.fromJson(json);

    if (_compareVersion(latest.tag, currentVersion) > 0) {
      return latest;
    }
    return null;
  }

  int _compareVersion(String a, String b) {
    final va = _parseVersion(a);
    final vb = _parseVersion(b);

    for (int i = 0; i < 3; i++) {
      final diff = va[i] - vb[i];
      if (diff != 0) return diff;
    }

    if (va.isPreRelease != vb.isPreRelease) {
      return va.isPreRelease ? -1 : 1;
    }

    return 0;
  }
}

class _ParsedVersion {
  final List<int> parts;
  final bool isPreRelease;

  _ParsedVersion(this.parts, this.isPreRelease);

  int operator [](int index) => parts[index];
}

_ParsedVersion _parseVersion(String version) {

  var v = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
  final parts = v.split('-');
  final numbers = parts.first.split('.');

  final parsed = List<int>.generate(
    3,
    (i) => i < numbers.length ? int.tryParse(numbers[i]) ?? 0 : 0,
  );

  return _ParsedVersion(
    parsed,
    parts.length > 1,
  );
}

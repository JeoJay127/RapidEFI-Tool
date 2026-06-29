//  github_api_client.dart 
//  Created by JeoJay127 
//
import 'dart:convert';
import '../http/http_client_manager.dart';


class GitHubApiClient {
  final HttpClientManager _httpClientManager = HttpClientManager();
  GitHubApiClient();

  static final Map<String, String> _baseHeaders = {
    'Accept': 'application/vnd.github+json',
  };

  Future<List<dynamic>?> getReleases({
    required String owner,
    required String repo,
    Function(dynamic error)? onError,
  }) async {
    final url =
        'https://api.github.com/repos/$owner/$repo/releases';

    final jsonStr = await _httpClientManager.getString(
      url,
      headers: _baseHeaders,
      onError: onError,
    );

    if (jsonStr == null) return null;
    return jsonDecode(jsonStr) as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getLatestRelease({
    required String owner,
    required String repo,
    Function(dynamic error)? onError,
  }) async {
    final url =
        'https://api.github.com/repos/$owner/$repo/releases/latest';

    final jsonStr = await _httpClientManager.getString(
      url,
      headers: _baseHeaders,
      onError: onError,
    );

    if (jsonStr == null) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }
}
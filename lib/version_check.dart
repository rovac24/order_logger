import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches the commit SHA baked into build_info.json at deploy time.
///
/// Uses a cache-busting query parameter (resolved against the current page
/// URL) so an intermediate cache can't mask a newer deploy, and a
/// per-request Cache-Control header for the same reason. Returns null if
/// the file can't be read — e.g. running locally without a deployed
/// build_info.json, or a transient network error — so a lookup failure
/// never surfaces as a false "update available" banner.
Future<String?> fetchDeployedCommit() async {
  final uri = Uri.base.resolve(
    'build_info.json?t=${DateTime.now().millisecondsSinceEpoch}',
  );

  try {
    final res = await http.get(uri, headers: {
      'Cache-Control': 'no-cache',
    });
    if (res.statusCode != 200) {
      return null;
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['commit'] as String?;
  } catch (_) {
    return null;
  }
}

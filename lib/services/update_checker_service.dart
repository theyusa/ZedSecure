import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:zedsecure/services/mmkv_manager.dart';

class UpdateCheckerService {
  static const String _githubApiUrl = 'https://api.github.com/repos/CluvexStudio/ZedSecure/releases/latest';
  static const String _githubReleasesUrl = 'https://github.com/CluvexStudio/ZedSecure/releases';
  static const String _lastCheckKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';

  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastCheck = MmkvManager.decodeSettingsInt(_lastCheckKey) ?? 0;

      if (now - lastCheck < 3600000) {
        debugPrint('Update check skipped: checked less than 1 hour ago');
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        final releaseNotes = data['body'] as String?;
        final publishedAt = data['published_at'] as String?;
        final downloadUrl = data['html_url'] as String;

        MmkvManager.encodeSettingsInt(_lastCheckKey, now);

        final skipVersion = MmkvManager.decodeSettings(_skipVersionKey);
        if (skipVersion == latestVersion) {
          debugPrint('Update skipped by user: $latestVersion');
          return null;
        }

        if (_isNewerVersion(currentVersion, latestVersion)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes ?? 'No release notes available',
            publishedAt: publishedAt,
            downloadUrl: downloadUrl,
          );
        } else {
          debugPrint('App is up to date: $currentVersion');
          return null;
        }
      } else {
        debugPrint('Failed to check for updates: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  static Future<void> skipVersion(String version) async {
    MmkvManager.encodeSettings(_skipVersionKey, version);
  }

  static Future<void> clearSkippedVersion() async {
    MmkvManager.removeSettings(_skipVersionKey);
  }

  static String get releasesUrl => _githubReleasesUrl;
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String? publishedAt;
  final String downloadUrl;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    this.publishedAt,
    required this.downloadUrl,
  });

  String get formattedPublishedDate {
    if (publishedAt == null) return 'Unknown';
    try {
      final date = DateTime.parse(publishedAt!);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

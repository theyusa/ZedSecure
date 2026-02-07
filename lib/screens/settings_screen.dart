import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/theme_service.dart';
import 'package:zedsecure/services/mmkv_manager.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:zedsecure/screens/per_app_proxy_screen.dart';
import 'package:zedsecure/screens/advanced_settings_screen.dart';
import 'package:zedsecure/screens/about_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoConnect = false;
  bool _killSwitch = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _autoConnect = MmkvManager.decodeSettingsBool('auto_connect');
      _killSwitch = MmkvManager.decodeSettingsBool('kill_switch');
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    MmkvManager.encodeSettingsBool(key, value);
  }

  void _showSnackBar(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1C1C1E), Colors.black]
              : [const Color(0xFFF2F2F7), Colors.white],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection('General', [
              _buildSwitchTile(
                'Auto Connect',
                'Automatically connect on app start',
                CupertinoIcons.play_circle_fill,
                AppTheme.connectedGreen,
                _autoConnect,
                (value) {
                  setState(() => _autoConnect = value);
                  _saveSetting('auto_connect', value);
                },
                isDark,
              ),
              _buildSwitchTile(
                'Kill Switch',
                'Block internet if VPN disconnects',
                CupertinoIcons.shield_fill,
                AppTheme.disconnectedRed,
                _killSwitch,
                (value) {
                  setState(() => _killSwitch = value);
                  _saveSetting('kill_switch', value);
                },
                isDark,
              ),
            ], isDark),
            const SizedBox(height: 20),
            _buildSection('Network', [
              _buildNavigationTile(
                'Advanced Settings',
                'Mux, Fragment, DNS & more',
                CupertinoIcons.slider_horizontal_3,
                const Color(0xFF5856D6),
                () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const AdvancedSettingsScreen()),
                ),
                isDark,
              ),
              _buildNavigationTile(
                'Per-App Proxy',
                'Choose which apps use VPN',
                CupertinoIcons.app_badge,
                AppTheme.primaryBlue,
                () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const PerAppProxyScreen())),
                isDark,
              ),
            ], isDark),
            const SizedBox(height: 20),
            _buildSection('Appearance', [
              Consumer<ThemeService>(
                builder: (context, themeService, child) {
                  final currentMode = themeService.themeMode == ThemeMode.dark 
                      ? 'Dark' 
                      : themeService.themeMode == ThemeMode.light 
                          ? 'Light' 
                          : 'Auto';
                  
                  return _buildNavigationTile(
                    'Theme',
                    currentMode,
                    CupertinoIcons.paintbrush,
                    Colors.indigo,
                    () => _showThemeSelector(themeService),
                    isDark,
                  );
                },
              ),
            ], isDark),
            const SizedBox(height: 20),
            _buildSection('Data', [
              _buildActionTile('Backup Configs', 'Export all configs', CupertinoIcons.cloud_upload_fill, Colors.teal, _backupConfigs, isDark),
              _buildActionTile('Restore Configs', 'Import from backup', CupertinoIcons.cloud_download_fill, Colors.cyan, _restoreConfigs, isDark),
              _buildActionTile('Clear Cache', 'Clear cached data', CupertinoIcons.trash, Colors.orange, _clearCache, isDark),
              _buildActionTile('Clear All Data', 'Reset everything', CupertinoIcons.delete, AppTheme.disconnectedRed, _clearAllData, isDark),
            ], isDark),
            const SizedBox(height: 20),
            _buildAboutSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.systemGray,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 60),
                      child: Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, Color color, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: color, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.systemGray)),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: AppTheme.connectedGreen),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(icon, color: color, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.systemGray)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 18, color: AppTheme.systemGray),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(icon, color: color, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.systemGray)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ABOUT',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.systemGray, letterSpacing: 0.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          ),
          child: _buildNavigationTile(
            'About ZedSecure',
            'Version 1.8.1 • Build 2026',
            CupertinoIcons.info_circle,
            AppTheme.primaryBlue,
            () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const AboutScreen()),
            ),
            isDark,
          ),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Link Copied', 'GitHub link copied to clipboard');
  }

  Future<void> _showThemeSelector(ThemeService themeService) async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Theme'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              themeService.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.device_phone_portrait, size: 20),
                const SizedBox(width: 8),
                const Text('Auto (System)'),
                if (themeService.themeMode == ThemeMode.system)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.checkmark, size: 20, color: AppTheme.primaryBlue),
                  ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              themeService.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.sun_max_fill, size: 20),
                const SizedBox(width: 8),
                const Text('Light'),
                if (themeService.themeMode == ThemeMode.light)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.checkmark, size: 20, color: AppTheme.primaryBlue),
                  ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              themeService.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.moon_fill, size: 20),
                const SizedBox(width: 8),
                const Text('Dark'),
                if (themeService.themeMode == ThemeMode.dark)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.checkmark, size: 20, color: AppTheme.primaryBlue),
                  ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached server data including ping results.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              final service = Provider.of<V2RayService>(context, listen: false);
              service.clearPingCache();
              _showSnackBar('Cache Cleared', 'All cached data has been cleared');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all servers, subscriptions, and settings. This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final service = Provider.of<V2RayService>(context, listen: false);
              await service.saveConfigs([]);
              await service.saveSubscriptions([]);
              service.clearPingCache();
              await MmkvManager.clearAll();
              _showSnackBar('All Data Cleared', 'App has been reset');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupConfigs() async {
    try {
      final service = Provider.of<V2RayService>(context, listen: false);
      final configs = await service.loadConfigs();
      final subscriptions = await service.loadSubscriptions();

      if (configs.isEmpty && subscriptions.isEmpty) {
        _showSnackBar('No Data', 'No configs or subscriptions to backup');
        return;
      }

      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'configs': configs.map((c) => c.toJson()).toList(),
        'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) directory = await getExternalStorageDirectory();
      } else {
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory!.path}/zedsecure_backup_$timestamp.json');
      await file.writeAsString(jsonString);
      _showSnackBar('Backup Created', 'Saved to: ${file.path}');
    } catch (e) {
      _showSnackBar('Backup Failed', e.toString());
    }
  }

  Future<void> _restoreConfigs() async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) directory = await getExternalStorageDirectory();
      } else {
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      final files = directory!.listSync()
          .where((f) => f.path.contains('zedsecure_backup_') && f.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        _showSnackBar('No Backups Found', 'No backup files found in Downloads folder');
        return;
      }

      files.sort((a, b) => b.path.compareTo(a.path));

      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Select Backup File'),
          actions: files.map((file) {
            final filename = file.path.split('/').last;
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _performRestore(file.path);
              },
              child: Text(filename),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Restore Failed', e.toString());
    }
  }

  Future<void> _performRestore(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      final service = Provider.of<V2RayService>(context, listen: false);
      int configsImported = 0;

      if (backupData['configs'] != null) {
        final configsList = backupData['configs'] as List;
        final existingConfigs = await service.loadConfigs();
        for (var configJson in configsList) {
          try {
            final configMap = configJson as Map<String, dynamic>;
            final fullConfig = configMap['fullConfig'] as String;
            final parsedConfigs = await service.parseSubscriptionContent(fullConfig);
            existingConfigs.addAll(parsedConfigs);
            configsImported++;
          } catch (e) {}
        }
        await service.saveConfigs(existingConfigs);
      }
      _showSnackBar('Restore Complete', 'Imported $configsImported config(s)');
    } catch (e) {
      _showSnackBar('Restore Failed', e.toString());
    }
  }
}

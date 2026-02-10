import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:zedsecure/services/mmkv_manager.dart';
import 'package:zedsecure/theme/app_theme.dart';

class PerAppProxyScreen extends StatefulWidget {
  const PerAppProxyScreen({super.key});

  @override
  State<PerAppProxyScreen> createState() => _PerAppProxyScreenState();
}

class _PerAppProxyScreenState extends State<PerAppProxyScreen> {
  List<Map<String, dynamic>> _apps = [];
  List<String> _selectedApps = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  static const MethodChannel _appListChannel = MethodChannel('com.zedsecure.vpn/app_list');

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final blockedAppsJson = MmkvManager.decodeSettings('blocked_apps');
      if (blockedAppsJson != null) {
        _selectedApps = List<String>.from(jsonDecode(blockedAppsJson));
      }
      
      final List<dynamic> result = await _appListChannel.invokeMethod('getInstalledApps');
      
      setState(() {
        _apps = result.map((app) => {
          'packageName': app['packageName'] as String,
          'name': app['name'] as String,
          'isSystemApp': app['isSystemApp'] as bool,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _saveSelection() async {
    MmkvManager.encodeSettings('blocked_apps', jsonEncode(_selectedApps));
    _showSnackBar('Saved', 'Selection saved (${_selectedApps.length} apps)');
  }

  List<Map<String, dynamic>> get _filteredApps {
    if (_searchQuery.isEmpty) return _apps;
    return _apps.where((app) {
      return app['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app['packageName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  List<Map<String, dynamic>> get _userApps {
    return _filteredApps.where((app) => !(app['isSystemApp'] as bool)).toList();
  }
  
  List<Map<String, dynamic>> get _systemApps {
    return _filteredApps.where((app) => app['isSystemApp'] as bool).toList();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Per-App Proxy',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSelection,
            child: Text('Save', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select apps to route through VPN',
                    style: TextStyle(fontSize: 13, color: AppTheme.systemGray),
                  ),
                  const SizedBox(height: 12),
                  CupertinoSearchTextField(
                    placeholder: 'Search apps...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedApps.length} of ${_apps.length} apps selected',
                      style: TextStyle(fontSize: 13, color: AppTheme.systemGray),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedApps = _apps.map((app) => app['packageName'] as String).toList()),
                    child: Text('All', style: TextStyle(fontSize: 13, color: theme.primaryColor, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _selectedApps.clear()),
                    child: Text('None', style: TextStyle(fontSize: 13, color: theme.primaryColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent(isDark, context)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(radius: 16),
            SizedBox(height: 16),
            Text('Loading apps...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: AppTheme.warningOrange),
              const SizedBox(height: 16),
              Text('Failed to load apps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: TextStyle(fontSize: 12, color: AppTheme.systemGray), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: _loadApps,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.app_badge, size: 48, color: AppTheme.systemGray),
            const SizedBox(height: 16),
            Text('No apps found', style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
      );
    }
    
    final filtered = _filteredApps;
    final userApps = _userApps;
    final systemApps = _systemApps;
    
    if (filtered.isEmpty) {
      return Center(
        child: Text('No apps match "$_searchQuery"', style: TextStyle(color: AppTheme.systemGray)),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (userApps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'USER APPS (${userApps.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.systemGray,
              ),
            ),
          ),
          ...userApps.map((app) => _buildAppTile(app, isDark, context)),
        ],
        if (systemApps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'SYSTEM APPS (${systemApps.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.systemGray,
              ),
            ),
          ),
          ...systemApps.map((app) => _buildAppTile(app, isDark, context)),
        ],
      ],
    );
  }
  
  Widget _buildAppTile(Map<String, dynamic> app, bool isDark, BuildContext context) {
    final packageName = app['packageName'] as String;
    final appName = app['name'] as String;
    final isSystemApp = app['isSystemApp'] as bool;
    final isSelected = _selectedApps.contains(packageName);
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.iosCardDecoration(isDark: isDark, context: context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: isSystemApp 
            ? Icon(CupertinoIcons.gear_alt, size: 20, color: AppTheme.systemGray)
            : Icon(CupertinoIcons.app, size: 20, color: theme.primaryColor),
        title: Text(
          appName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          packageName,
          style: TextStyle(fontSize: 11, color: AppTheme.systemGray),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: CupertinoSwitch(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value) {
                _selectedApps.add(packageName);
              } else {
                _selectedApps.remove(packageName);
              }
            });
          },
          activeTrackColor: AppTheme.connectedGreen,
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedApps.remove(packageName);
            } else {
              _selectedApps.add(packageName);
            }
          });
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/services/app_settings_service.dart';
import 'package:zedsecure/models/app_settings.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:zedsecure/widgets/custom_glass_popup.dart';
import 'package:zedsecure/widgets/custom_glass_action_sheet.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = Provider.of<AppSettingsService>(context);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Advanced Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('VPN SETTINGS', [
            _buildSwitchTile(
              'Prefer IPv6',
              'Use IPv6 when available',
              CupertinoIcons.number,
              const Color(0xFF5856D6),
              service.preferIpv6,
              (value) => service.setPreferIpv6(value),
              isDark,
            ),
            _buildSwitchTile(
              'Local DNS',
              'Enable local DNS server',
              CupertinoIcons.globe,
              AppTheme.primaryBlue,
              service.localDnsEnabled,
              (value) async {
                await service.setLocalDnsEnabled(value);
                if (value) {
                  await service.setFakeDnsEnabled(true);
                }
              },
              isDark,
            ),
            _buildSwitchTile(
              'Fake DNS',
              'Enable Fake DNS for better routing',
              CupertinoIcons.shield,
              Colors.orange,
              service.fakeDnsEnabled,
              (value) => service.setFakeDnsEnabled(value),
              isDark,
              enabled: !service.localDnsEnabled,
            ),
            _buildSwitchTile(
              'HTTP Proxy',
              'Append HTTP proxy to VPN',
              CupertinoIcons.arrow_right_arrow_left,
              Colors.teal,
              service.appendHttpProxy,
              (value) => service.setAppendHttpProxy(value),
              isDark,
            ),
            _buildSwitchTile(
              'Bypass LAN',
              'Bypass local network traffic',
              CupertinoIcons.wifi,
              Colors.green,
              service.bypassLan,
              (value) => service.setBypassLan(value),
              isDark,
            ),
            _buildTextFieldTile(
              'VPN Interface Address',
              service.vpnInterfaceAddress,
              CupertinoIcons.location,
              Colors.purple,
              (value) => service.setVpnInterfaceAddress(value),
              isDark,
              hint: '10.0.0.2',
            ),
            _buildNumberFieldTile(
              'VPN MTU',
              service.vpnMtu.toString(),
              CupertinoIcons.number,
              Colors.indigo,
              (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  service.setVpnMtu(parsed);
                }
              },
              isDark,
              hint: '1500',
            ),
          ], isDark),
          const SizedBox(height: 20),
          _buildSection('CORE SETTINGS', [
            _buildSwitchTile(
              'Sniffing',
              'Enable traffic sniffing',
              CupertinoIcons.eye,
              Colors.cyan,
              service.sniffingEnabled,
              (value) => service.setSniffingEnabled(value),
              isDark,
            ),
            _buildSwitchTile(
              'Route Only',
              'Only route, don\'t proxy',
              CupertinoIcons.arrow_branch,
              Colors.pink,
              service.routeOnlyEnabled,
              (value) => service.setRouteOnlyEnabled(value),
              isDark,
            ),
            _buildSwitchTile(
              'Proxy Sharing',
              'Share proxy with other apps',
              CupertinoIcons.share,
              Colors.blue,
              service.proxySharingEnabled,
              (value) => service.setProxySharingEnabled(value),
              isDark,
            ),
            _buildSwitchTile(
              'Allow Insecure',
              'Allow insecure TLS connections',
              CupertinoIcons.exclamationmark_triangle,
              AppTheme.disconnectedRed,
              service.allowInsecure,
              (value) => service.setAllowInsecure(value),
              isDark,
            ),
            _buildNumberFieldTile(
              'SOCKS Port',
              service.socksPort.toString(),
              CupertinoIcons.number,
              Colors.deepPurple,
              (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0 && parsed <= 65535) {
                  service.setSocksPort(parsed);
                }
              },
              isDark,
              hint: '10808',
            ),
            _buildTextFieldTile(
              'Remote DNS',
              service.remoteDns,
              CupertinoIcons.globe,
              Colors.blue,
              (value) => service.setRemoteDns(value),
              isDark,
              hint: '1.1.1.1',
            ),
            _buildTextFieldTile(
              'Domestic DNS',
              service.domesticDns,
              CupertinoIcons.globe,
              Colors.green,
              (value) => service.setDomesticDns(value),
              isDark,
              hint: '223.5.5.5',
            ),
            _buildTextFieldTile(
              'DNS Hosts',
              service.dnsHosts,
              CupertinoIcons.doc_text,
              Colors.orange,
              (value) => service.setDnsHosts(value),
              isDark,
              hint: 'domain:ip,domain:ip',
            ),
            _buildDropdownTile(
              'Log Level',
              service.coreLogLevel,
              ['debug', 'info', 'warning', 'error', 'none'],
              CupertinoIcons.doc_plaintext,
              Colors.grey,
              (value) => service.setCoreLogLevel(value),
              isDark,
            ),
            _buildDropdownTile(
              'Domain Resolve',
              service.outboundDomainResolveMethod == 0 ? 'AsIs' : service.outboundDomainResolveMethod == 1 ? 'UseIP' : 'UseIPv4',
              ['AsIs', 'UseIP', 'UseIPv4'],
              CupertinoIcons.arrow_right_arrow_left_circle,
              Colors.teal,
              (value) {
                final method = value == 'AsIs' ? 0 : value == 'UseIP' ? 1 : 2;
                service.setOutboundDomainResolveMethod(method);
              },
              isDark,
            ),
          ], isDark),
          const SizedBox(height: 20),
          _buildSection('MUX & FRAGMENT', [
            _buildActionTile(
              'Mux Settings',
              service.muxSettings.enabled ? 'Enabled (${service.muxSettings.concurrency})' : 'Disabled',
              CupertinoIcons.arrow_merge,
              const Color(0xFF5856D6),
              () => _showMuxDialog(service),
              isDark,
            ),
            _buildActionTile(
              'Fragment Settings',
              service.fragmentSettings.enabled ? 'Enabled (${service.fragmentSettings.packets})' : 'Disabled',
              CupertinoIcons.square_split_2x2,
              Colors.orange,
              () => _showFragmentDialog(service),
              isDark,
            ),
          ], isDark),
          const SizedBox(height: 20),
          _buildSection('SUBSCRIPTION', [
            _buildSwitchTile(
              'Auto Update',
              'Update subscriptions automatically',
              CupertinoIcons.arrow_clockwise,
              Colors.blue,
              service.autoUpdateSubscription,
              (value) => service.setAutoUpdateSubscription(value),
              isDark,
            ),
            _buildNumberFieldTile(
              'Update Interval (hours)',
              service.autoUpdateInterval.toString(),
              CupertinoIcons.timer,
              Colors.cyan,
              (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  service.setAutoUpdateInterval(parsed);
                }
              },
              isDark,
              hint: '24',
            ),
          ], isDark),
          const SizedBox(height: 20),
          _buildSection('TESTING', [
            _buildSwitchTile(
              'Auto Remove Invalid',
              'Remove invalid servers after test',
              CupertinoIcons.trash,
              AppTheme.disconnectedRed,
              service.autoRemoveInvalidAfterTest,
              (value) => service.setAutoRemoveInvalidAfterTest(value),
              isDark,
            ),
            _buildSwitchTile(
              'Auto Sort',
              'Sort servers by ping after test',
              CupertinoIcons.sort_down,
              Colors.green,
              service.autoSortAfterTest,
              (value) => service.setAutoSortAfterTest(value),
              isDark,
            ),
            _buildTextFieldTile(
              'Test URL',
              service.connectionTestUrl,
              CupertinoIcons.link,
              Colors.blue,
              (value) => service.setConnectionTestUrl(value),
              isDark,
              hint: 'https://www.google.com/generate_204',
            ),
            _buildTextFieldTile(
              'IP API URL',
              service.ipApiUrl,
              CupertinoIcons.location,
              Colors.purple,
              (value) => service.setIpApiUrl(value),
              isDark,
              hint: 'https://api.ipify.org',
            ),
          ], isDark),
          const SizedBox(height: 20),
          _buildSection('MODE', [
            _buildDropdownTile(
              'Mode',
              service.mode,
              ['VPN', 'Proxy'],
              CupertinoIcons.arrow_right_arrow_left_circle,
              Colors.indigo,
              (value) => service.setMode(value),
              isDark,
            ),
            _buildSwitchTile(
              'Proxy Only Mode',
              'Use proxy without VPN (deprecated)',
              CupertinoIcons.arrow_right_arrow_left,
              Colors.grey,
              service.proxyOnlyMode,
              (value) => service.setProxyOnlyMode(value),
              isDark,
            ),
          ], isDark),
          const SizedBox(height: 20),
          _buildSection('HEVTUN SETTINGS', [
            _buildSwitchTile(
              'Use HevTun',
              'HevTun tunnel (Always enabled)',
              CupertinoIcons.arrow_up_arrow_down_circle,
              AppTheme.primaryBlue,
              true,
              (value) {},
              isDark,
              enabled: false,
            ),
            _buildDropdownTile(
              'Log Level',
              service.hevTunnelLogLevel,
              ['debug', 'info', 'warn', 'error', 'silent'],
              CupertinoIcons.doc_plaintext,
              Colors.orange,
              (value) => service.setHevTunnelLogLevel(value),
              isDark,
            ),
            _buildTextFieldTile(
              'RW Timeout',
              service.hevTunnelRwTimeout,
              CupertinoIcons.timer,
              Colors.purple,
              (value) => service.setHevTunnelRwTimeout(value),
              isDark,
              hint: '300,60',
            ),
          ], isDark),
          const SizedBox(height: 100),
        ],
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
            title,
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

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, Color color, bool value, ValueChanged<bool> onChanged, bool isDark, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(enabled ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: color.withOpacity(enabled ? 1.0 : 0.3), size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, color: (isDark ? Colors.white : Colors.black).withOpacity(enabled ? 1.0 : 0.4))),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.systemGray.withOpacity(enabled ? 1.0 : 0.6))),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: enabled ? onChanged : null, activeTrackColor: AppTheme.connectedGreen),
        ],
      ),
    );
  }

  Widget _buildTextFieldTile(String title, String value, IconData icon, Color color, ValueChanged<String> onChanged, bool isDark, {String? hint}) {
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
                Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                CupertinoTextField(
                  controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
                  onChanged: onChanged,
                  placeholder: hint,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberFieldTile(String title, String value, IconData icon, Color color, ValueChanged<String> onChanged, bool isDark, {String? hint}) {
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
                Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                CupertinoTextField(
                  controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
                  onChanged: onChanged,
                  keyboardType: TextInputType.number,
                  placeholder: hint,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String title, String value, List<String> options, IconData icon, Color color, ValueChanged<String> onChanged, bool isDark) {
    return GestureDetector(
      onTap: () {
        CustomGlassActionSheet.show(
          context: context,
          cancelText: 'Cancel',
          actions: options.map((option) {
            final isSelected = option == value;
            return CustomGlassActionSheetItem(
              title: option,
              trailing: isSelected
                  ? Icon(CupertinoIcons.checkmark, size: 20, color: AppTheme.primaryBlue)
                  : null,
              isDefault: isSelected,
              onTap: () {
                onChanged(option);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
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
                  Text(value, style: TextStyle(fontSize: 12, color: AppTheme.systemGray)),
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
            Icon(CupertinoIcons.chevron_right, size: 18, color: AppTheme.systemGray),
          ],
        ),
      ),
    );
  }

  Future<void> _showMuxDialog(AppSettingsService service) async {
    bool enabled = service.muxSettings.enabled;
    int concurrency = service.muxSettings.concurrency;
    int xudpConcurrency = service.muxSettings.xudpConcurrency;
    String xudpQuic = service.muxSettings.xudpQuic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await CustomGlassPopup.show(
      context: context,
      title: 'Mux Settings',
      leadingIcon: Icon(CupertinoIcons.arrow_merge),
      iconColor: const Color(0xFF5856D6),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enable Mux', style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
                  CupertinoSwitch(
                    value: enabled,
                    onChanged: (value) => setState(() => enabled = value),
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Concurrency', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                    SizedBox(
                      width: 80,
                      child: CupertinoTextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        controller: TextEditingController(text: concurrency.toString())
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: concurrency.toString().length),
                          ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0 && parsed <= 32) {
                            setState(() => concurrency = parsed);
                          }
                        },
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.systemGray.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('XUDP Concurrency', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                    SizedBox(
                      width: 80,
                      child: CupertinoTextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        controller: TextEditingController(text: xudpConcurrency.toString())
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: xudpConcurrency.toString().length),
                          ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0 && parsed <= 32) {
                            setState(() => xudpConcurrency = parsed);
                          }
                        },
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.systemGray.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('XUDP QUIC', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                    GestureDetector(
                      onTap: () {
                        CustomGlassActionSheet.show(
                          context: context,
                          cancelText: 'Cancel',
                          actions: ['reject', 'allow', 'skip'].map((mode) {
                            return CustomGlassActionSheetItem(
                              title: mode,
                              isDefault: mode == xudpQuic,
                              onTap: () {
                                setState(() => xudpQuic = mode);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(xudpQuic, style: TextStyle(fontSize: 14, color: AppTheme.primaryBlue)),
                          const SizedBox(width: 4),
                          Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.systemGray),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Enable Mux to configure options',
                  style: TextStyle(fontSize: 12, color: AppTheme.systemGray),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: isDark ? Colors.white12 : Colors.black12,
          borderRadius: BorderRadius.circular(12),
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
          onPressed: () async {
            final newSettings = MuxSettings(
              enabled: enabled,
              concurrency: concurrency,
              xudpConcurrency: xudpConcurrency,
              xudpQuic: xudpQuic,
            );
            await service.setMuxSettings(newSettings);
            Navigator.pop(context);
          },
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFragmentDialog(AppSettingsService service) async {
    bool enabled = service.fragmentSettings.enabled;
    String packets = service.fragmentSettings.packets;
    final lengthController = TextEditingController(text: service.fragmentSettings.length);
    final intervalController = TextEditingController(text: service.fragmentSettings.interval);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await CustomGlassPopup.show(
      context: context,
      title: 'Fragment Settings',
      leadingIcon: Icon(CupertinoIcons.square_split_)2x2,
      iconColor: Colors.orange,
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enable Fragment', style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black)),
                  CupertinoSwitch(
                    value: enabled,
                    onChanged: (value) => setState(() => enabled = value),
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Packets', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                    GestureDetector(
                      onTap: () {
                        CustomGlassActionSheet.show(
                          context: context,
                          cancelText: 'Cancel',
                          actions: ['tlshello', '1-2', '1-3', '1-5'].map((p) {
                            return CustomGlassActionSheetItem(
                              title: p,
                              isDefault: p == packets,
                              onTap: () {
                                setState(() => packets = p);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(packets, style: TextStyle(fontSize: 14, color: AppTheme.primaryBlue)),
                          const SizedBox(width: 4),
                          Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.systemGray),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Length', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87))),
                    SizedBox(
                      width: 80,
                      child: CupertinoTextField(
                        controller: lengthController,
                        placeholder: '50-100',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.systemGray.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Interval', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87))),
                    SizedBox(
                      width: 80,
                      child: CupertinoTextField(
                        controller: intervalController,
                        placeholder: '10-20',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.systemGray.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Enable Fragment to configure options',
                  style: TextStyle(fontSize: 12, color: AppTheme.systemGray),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: isDark ? Colors.white12 : Colors.black12,
          borderRadius: BorderRadius.circular(12),
          onPressed: () {
            lengthController.dispose();
            intervalController.dispose();
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
          onPressed: () async {
            final newSettings = FragmentSettings(
              enabled: enabled,
              packets: packets,
              length: lengthController.text.trim(),
              interval: intervalController.text.trim(),
            );
            await service.setFragmentSettings(newSettings);
            lengthController.dispose();
            intervalController.dispose();
            Navigator.pop(context);
          },
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

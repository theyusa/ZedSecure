import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/country_detector.dart';
import 'package:zedsecure/services/log_service.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:zedsecure/widgets/custom_glass_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isConnecting = false;
  bool _isDetectingLocation = false;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  V2RayConfig? _selectedConfig;
  final GlobalKey<_PingTextWidgetState> _pingKey = GlobalKey<_PingTextWidgetState>();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadSelectedConfig();
    final service = Provider.of<V2RayService>(context, listen: false);
    service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    _loadSelectedConfig();
  }

  Future<void> _loadSelectedConfig() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    final config = await service.loadSelectedConfig();
    if (mounted) {
      setState(() => _selectedConfig = config);
    }
  }

  @override
  void dispose() {
    final service = Provider.of<V2RayService>(context, listen: false);
    service.removeListener(_onServiceChanged);
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<V2RayService>(
      builder: (context, v2rayService, child) {
        final isConnected = v2rayService.isConnected;
        final activeConfig = v2rayService.activeConfig;
        final status = v2rayService.currentStatus;
        final displayConfig = activeConfig ?? _selectedConfig;

        return Container(
          color: theme.scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (isConnected && status != null)
                  _buildDynamicIsland(v2rayService, status, isDark, context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _showLogViewer(context, isDark),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.doc_text,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Logs',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildConnectionWidget(isConnected, v2rayService, isDark, context),
                        const SizedBox(height: 40),
                        if (displayConfig != null)
                          _buildServerCard(displayConfig, v2rayService, isConnected, isDark, context)
                        else
                          _buildNoServerCard(isDark, context),
                        const SizedBox(height: 20),
                        if (isConnected && status != null) ...[
                          _buildConnectionInfoGrid(v2rayService, isDark, context),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicIsland(V2RayService service, dynamic status, bool isDark, BuildContext context) {
    final duration = status.duration ?? '00:00:00';
    final uploadSpeed = AppTheme.formatSpeed(status.uploadSpeed);
    final downloadSpeed = AppTheme.formatSpeed(status.downloadSpeed);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppTheme.connectedGreen.withOpacity(0.15 + (_pulseController.value * 0.08)),
                blurRadius: 15,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.connectedGreen,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.connectedGreen.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.systemGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.connectedGreen.withOpacity(0.12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up,
                      size: 10,
                      color: AppTheme.connectedGreen,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      uploadSpeed,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.connectedGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).primaryColor.withOpacity(0.12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_down,
                      size: 10,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      downloadSpeed,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => service.disconnect(),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.disconnectedRed.withOpacity(0.12),
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 12,
                    color: AppTheme.disconnectedRed,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionWidget(bool isConnected, V2RayService service, bool isDark, BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _isConnecting ? null : () => _handleConnectionToggle(service),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: _RingPainter(
                      isConnected: isConnected,
                      progress: isConnected ? 1.0 : 0.3,
                      primaryColor: theme.primaryColor,
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: (isConnected ? AppTheme.connectedGreen : theme.primaryColor).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: _isConnecting
                    ? const CupertinoActivityIndicator(radius: 18)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.shield_fill,
                            size: 44,
                            color: isConnected ? AppTheme.connectedGreen : theme.primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isConnected ? 'Protected' : 'Connect',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isConnected ? AppTheme.connectedGreen : theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoServerCard(bool isDark, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.iosCardDecoration(isDark: isDark, context: context),
      child: Column(
        children: [
          Icon(CupertinoIcons.globe, size: 48, color: AppTheme.systemGray),
          const SizedBox(height: 12),
          Text(
            'No Server Selected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Go to Servers tab to select one',
            style: TextStyle(fontSize: 13, color: AppTheme.systemGray),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagWidget(String countryCode) {
    final code = countryCode.toLowerCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SvgPicture.asset(
        'assets/flags/$code.svg',
        width: 48,
        height: 36,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _buildFallbackFlag(countryCode),
      ),
    );
  }

  Widget _buildFallbackFlag(String countryCode) {
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          countryCode.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildServerCard(V2RayConfig config, V2RayService service, bool isConnected, bool isDark, BuildContext context) {
    final countryCode = service.detectedCountryCode ?? 'XX';
    final detectedIP = service.detectedIP;
    final detectedCity = service.detectedCity;
    final detectedRegion = service.detectedRegion;
    final theme = Theme.of(context);
    
    String locationText = 'Unknown Location';
    if (detectedCity != null && detectedRegion != null) {
      locationText = '$detectedCity, $detectedRegion';
    } else if (detectedCity != null) {
      locationText = detectedCity;
    } else if (countryCode != 'XX') {
      locationText = CountryDetector.getCountryName(countryCode);
    }
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.iosCardDecoration(isDark: isDark, context: context),
          child: Row(
            children: [
              _buildFlagWidget(countryCode),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isConnected)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.connectedGreen,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            config.remark,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationText,
                      style: TextStyle(fontSize: 13, color: AppTheme.systemGray),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: theme.primaryColor.withOpacity(0.12),
                          ),
                          child: Text(
                            config.protocolDisplay,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.primaryColor),
                          ),
                        ),
                        if (!isConnected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.warningOrange.withOpacity(0.12),
                            ),
                            child: Text(
                              'Selected',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.warningOrange),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionInfoGrid(V2RayService service, bool isDark, BuildContext context) {
    final status = service.currentStatus;
    final detectedCountryCode = service.detectedCountryCode ?? 'XX';
    final detectedIP = service.detectedIP;
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.iosCardDecoration(isDark: isDark, context: context),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SvgPicture.asset(
                          'assets/flags/${detectedCountryCode.toLowerCase()}.svg',
                          width: 36,
                          height: 27,
                          fit: BoxFit.cover,
                          placeholderBuilder: (context) => Text(
                            detectedCountryCode.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IP Address',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.systemGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detectedIP ?? 'Detecting...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _isDetectingLocation ? null : () async {
                      setState(() => _isDetectingLocation = true);
                      await service.detectRealCountry();
                      if (mounted) setState(() => _isDetectingLocation = false);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      ),
                      child: Center(
                        child: _isDetectingLocation
                            ? const CupertinoActivityIndicator(radius: 10)
                            : Icon(
                                CupertinoIcons.arrow_clockwise,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.warningOrange.withOpacity(0.15),
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.bolt_fill,
                        size: 26,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latency',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.systemGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _PingTextWidget(key: _pingKey, service: service, isDark: isDark),
                      ],
                    ),
                  ),
                  _PingRefreshButton(
                    pingKey: _pingKey,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor.withOpacity(0.15),
                            ),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.arrow_down,
                                size: 22,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Download',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.systemGray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppTheme.formatSpeed(status!.downloadSpeed),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.connectedGreen.withOpacity(0.15),
                            ),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.arrow_up,
                                size: 22,
                                color: AppTheme.connectedGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.systemGray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppTheme.formatSpeed(status.uploadSpeed),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color.withOpacity(0.12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.systemGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnectionToggle(V2RayService service) async {
    setState(() => _isConnecting = true);
    try {
      if (service.isConnected) {
        await service.disconnect();
      } else {
        final selectedConfig = await service.loadSelectedConfig();
        if (selectedConfig == null) {
          final configs = await service.loadConfigs();
          if (configs.isEmpty) {
            _showSnackBar('No Servers', 'Please add servers from Subscriptions');
          } else {
            _showSnackBar('No Server Selected', 'Please select a server first');
          }
        } else {
          setState(() => _selectedConfig = selectedConfig);
          final success = await service.connect(selectedConfig);
          if (!success) _showSnackBar('Connection Failed', 'Failed to connect');
        }
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
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

  void _showLogViewer(BuildContext context, bool isDark) {
    final logger = LogService();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.95),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Connection Logs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.trash,
                            color: AppTheme.disconnectedRed,
                          ),
                          onPressed: () {
                            logger.clear();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: AppTheme.systemGray,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: logger,
                      builder: (context, child) {
                        final logs = logger.logs;
                        
                        if (logs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 64,
                                  color: AppTheme.systemGray,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No logs yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.systemGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Logs will appear here when you connect',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.systemGray,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            Color levelColor;
                            
                            switch (log.level) {
                              case LogLevel.error:
                                levelColor = AppTheme.disconnectedRed;
                                break;
                              case LogLevel.warning:
                                levelColor = Colors.orange;
                                break;
                              case LogLevel.info:
                                levelColor = AppTheme.primaryBlue;
                                break;
                              case LogLevel.debug:
                                levelColor = AppTheme.systemGray;
                                break;
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: levelColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SelectableText(
                                      log.toString(),
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getDebugLogs() async {
    return 'Debug logs will appear here during connection.\n\n'
        'Check your IDE console (flutter run) for detailed logs:\n'
        '- V2Ray connection process\n'
        '- FluxTun startup\n'
        '- VPN interface setup\n'
        '- Config parsing\n\n'
        'Note: Logs are printed to console using debugPrint()';
  }
}

class _PingTextWidget extends StatefulWidget {
  final V2RayService service;
  final bool isDark;

  const _PingTextWidget({super.key, required this.service, required this.isDark});

  @override
  State<_PingTextWidget> createState() => _PingTextWidgetState();
}

class _PingTextWidgetState extends State<_PingTextWidget> {
  int? _ping;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service.isConnected) {
      _loadPing();
    }
  }

  @override
  void didUpdateWidget(_PingTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final wasConnected = oldWidget.service.isConnected;
    final isNowConnected = widget.service.isConnected;
    
    if (isNowConnected && !wasConnected) {
      _loadPing();
    } else if (!isNowConnected && wasConnected) {
      if (mounted) {
        setState(() {
          _ping = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refresh() async {
    if (_isLoading || !widget.service.isConnected) return;
    await _loadPing();
  }

  Future<void> _loadPing() async {
    if (!mounted || !widget.service.isConnected || _isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔍 Starting ping measurement...');
      final startTime = DateTime.now();
      
      final ping = await widget.service.getConnectedServerDelay()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ Ping measurement timeout after 10 seconds');
              return null;
            },
          );
      
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('✅ Ping completed in ${elapsed}ms, result: $ping ms');
      
      if (mounted) {
        setState(() {
          _ping = ping;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading ping: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _ping = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.service.isConnected) {
      return Text(
        'Not connected',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.systemGray,
        ),
      );
    }

    if (_isLoading) {
      return Text(
        'Measuring...',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.systemGray,
        ),
      );
    }

    return Text(
      _ping != null && _ping! >= 0 ? '$_ping ms' : 'Unavailable',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _ping != null && _ping! >= 0
            ? AppTheme.getPingColor(_ping!)
            : AppTheme.systemGray,
      ),
    );
  }
}

class _PingRefreshButton extends StatefulWidget {
  final GlobalKey<_PingTextWidgetState> pingKey;
  final bool isDark;

  const _PingRefreshButton({
    required this.pingKey,
    required this.isDark,
  });

  @override
  State<_PingRefreshButton> createState() => _PingRefreshButtonState();
}

class _PingRefreshButtonState extends State<_PingRefreshButton> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      await widget.pingKey.currentState?.refresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isRefreshing ? null : _handleRefresh,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        ),
        child: Center(
          child: _isRefreshing
              ? const CupertinoActivityIndicator(radius: 10)
              : Icon(
                  CupertinoIcons.arrow_clockwise,
                  size: 18,
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final bool isConnected;
  final double progress;
  final Color primaryColor;

  _RingPainter({required this.isConnected, required this.progress, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    final bgPaint = Paint()
      ..color = (isConnected ? AppTheme.connectedGreen : primaryColor).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: isConnected
            ? [AppTheme.connectedGreen.withOpacity(0.2), AppTheme.connectedGreen]
            : [primaryColor.withOpacity(0.2), primaryColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.isConnected != isConnected || oldDelegate.progress != progress || oldDelegate.primaryColor != primaryColor;
  }
}

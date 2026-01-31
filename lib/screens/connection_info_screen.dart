import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConnectionInfoScreen extends StatefulWidget {
  const ConnectionInfoScreen({super.key});

  @override
  State<ConnectionInfoScreen> createState() => _ConnectionInfoScreenState();
}

class _ConnectionInfoScreenState extends State<ConnectionInfoScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _ipInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchIpInfo();
  }

  Future<void> _fetchIpInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        setState(() {
          _ipInfo = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch IP information';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Connection Info',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.refresh, color: isDark ? Colors.white : Colors.black),
            onPressed: _fetchIpInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 16))
          : _error != null
              ? _buildError(isDark)
              : _buildContent(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: AppTheme.disconnectedRed,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: _fetchIpInfo,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_ipInfo == null) return const SizedBox();

    final ip = _ipInfo!['ip'] ?? 'N/A';
    final country = _ipInfo!['country_name'] ?? 'Unknown';
    final countryCode = (_ipInfo!['country_code'] ?? 'XX').toString().toLowerCase();
    final city = _ipInfo!['city'] ?? 'Unknown';
    final isp = _ipInfo!['org'] ?? 'Unknown';
    final asn = _ipInfo!['asn'] ?? 'N/A';
    final ipVersion = _ipInfo!['version'] ?? 'IPv4';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/flags/$countryCode.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.primaryBlue.withOpacity(0.15),
                          child: Center(
                            child: Text(
                              countryCode.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ip,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  country,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.systemGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DETAILS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.systemGray,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('IP Version', ipVersion, CupertinoIcons.number, isDark),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 12),
                _buildDetailRow('ISP', isp, CupertinoIcons.building_2_fill, isDark),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 12),
                _buildDetailRow('ASN', asn, CupertinoIcons.number_square, isDark),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 12),
                _buildDetailRow('Country Code', countryCode.toUpperCase(), CupertinoIcons.flag, isDark),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 12),
                _buildDetailRow('City', city, CupertinoIcons.location_solid, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.systemGray,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

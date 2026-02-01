import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/theme_service.dart';
import 'package:zedsecure/models/subscription.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/theme/app_theme.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<Subscription> _subscriptions = [];
  Subscription? _suggestedSubscription;
  bool _isLoading = true;
  bool _isSuggestedActive = false;

  @override
  void initState() {
    super.initState();
    _initializeSuggestedSubscription();
    _loadSubscriptions();
  }

  void _initializeSuggestedSubscription() {
    _suggestedSubscription = Subscription(
      id: 'suggested_cloudflare_plus',
      name: 'Suggested - CloudflarePlus',
      url: 'https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/refs/heads/main/proxy',
      lastUpdate: DateTime.now(),
      configCount: 0,
    );
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    final service = Provider.of<V2RayService>(context, listen: false);
    final subs = await service.loadSubscriptions();
    final hasSuggested = subs.any((sub) => sub.id == 'suggested_cloudflare_plus');
    if (hasSuggested) _isSuggestedActive = true;
    setState(() {
      _subscriptions = subs;
      _isLoading = false;
    });
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
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator(radius: 16))
                  : _buildContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Subscriptions',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showAddSubscriptionDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        if (_subscriptions.isNotEmpty) ...[
          _buildSectionHeader('My Subscriptions', CupertinoIcons.cloud_fill, AppTheme.primaryBlue, isDark),
          ..._subscriptions.map((sub) => _buildSubscriptionCard(sub, isDark)),
        ],
        if (_subscriptions.isEmpty)
          _buildEmptyState(isDark),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(CupertinoIcons.cloud, size: 64, color: AppTheme.systemGray),
          const SizedBox(height: 16),
          Text(
            'No custom subscriptions',
            style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a subscription to get started',
            style: TextStyle(fontSize: 14, color: AppTheme.systemGray),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard(Subscription subscription, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.orange.withOpacity(0.15), Colors.yellow.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.orange, Colors.yellow]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.cloud_download_fill, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Free CloudflarePlus servers',
                  style: TextStyle(fontSize: 12, color: AppTheme.systemGray),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _activateSuggestedSubscription(subscription),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Activate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Subscription subscription, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(CupertinoIcons.cloud_fill, color: AppTheme.primaryBlue, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subscription.configCount} servers • ${_formatDate(subscription.lastUpdate)}',
                      style: TextStyle(fontSize: 12, color: AppTheme.systemGray),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _updateSubscription(subscription),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(CupertinoIcons.refresh, size: 20, color: AppTheme.primaryBlue),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteSubscription(subscription),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(CupertinoIcons.trash, size: 20, color: AppTheme.disconnectedRed),
                ),
              ),
            ],
          ),
          if (subscription.hasTrafficInfo || subscription.hasExpireInfo) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (subscription.hasTrafficInfo) ...[
                    Row(
                      children: [
                        Icon(CupertinoIcons.arrow_up_arrow_down, size: 14, color: AppTheme.systemGray),
                        const SizedBox(width: 6),
                        Text(
                          'Traffic: ${_formatBytes(subscription.consumption)} / ${_formatBytes(subscription.total!)}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: subscription.ratio,
                        backgroundColor: AppTheme.systemGray.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          subscription.ratio > 0.9 ? AppTheme.disconnectedRed : AppTheme.primaryBlue,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  if (subscription.hasTrafficInfo && subscription.hasExpireInfo)
                    const SizedBox(height: 8),
                  if (subscription.hasExpireInfo) ...[
                    Row(
                      children: [
                        Icon(
                          subscription.isExpired ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.clock,
                          size: 14,
                          color: subscription.isExpired ? AppTheme.disconnectedRed : AppTheme.systemGray,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subscription.isExpired
                              ? 'Expired'
                              : 'Expires in ${_formatDuration(subscription.remaining!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: subscription.isExpired
                                ? AppTheme.disconnectedRed
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1099511627776) return '${(bytes / 1099511627776).toStringAsFixed(2)} TB';
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 365) return '${(duration.inDays / 365).floor()}y';
    if (duration.inDays > 30) return '${(duration.inDays / 30).floor()}mo';
    if (duration.inDays > 0) return '${duration.inDays}d';
    if (duration.inHours > 0) return '${duration.inHours}h';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return 'soon';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _showAddSubscriptionDialog() async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.add_circled_solid, color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Add Subscription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: nameController,
                placeholder: 'My Subscription',
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Subscription URL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: urlController,
                placeholder: 'https://example.com/subscription',
                padding: const EdgeInsets.all(14),
                keyboardType: TextInputType.url,
                maxLines: 3,
                minLines: 1,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () async {
                        if (nameController.text.isEmpty || urlController.text.isEmpty) return;
                        Navigator.pop(context);
                        await _addSubscription(nameController.text, urlController.text);
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSubscription(String name, String url) async {
    _showSnackBar('Loading', 'Fetching servers...');
    final service = Provider.of<V2RayService>(context, listen: false);
    try {
      final subscriptionId = DateTime.now().millisecondsSinceEpoch.toString();
      final result = await service.parseSubscriptionUrl(url, subscriptionId: subscriptionId);
      final configs = (result['configs'] as List).cast<V2RayConfig>();
      final subInfo = result['subInfo'] as Map<String, dynamic>?;
      
      if (configs.isEmpty) {
        _showSnackBar('Error', 'No servers found in subscription');
        return;
      }
      
      final existingConfigs = await service.loadConfigs();
      final existingFullConfigs = existingConfigs.map((c) => c.fullConfig).toSet();
      final newConfigs = configs.where((config) => !existingFullConfigs.contains(config.fullConfig)).toList();
      final allConfigs = [...existingConfigs, ...newConfigs];
      await service.saveConfigs(allConfigs);

      final subscription = Subscription(
        id: subscriptionId,
        name: name,
        url: url,
        lastUpdate: DateTime.now(),
        configCount: newConfigs.isNotEmpty ? newConfigs.length : configs.length,
        upload: subInfo?['upload'] as int?,
        download: subInfo?['download'] as int?,
        total: subInfo?['total'] as int?,
        expire: subInfo?['expire'] as DateTime?,
      );
      _subscriptions.add(subscription);
      await service.saveSubscriptions(_subscriptions);
      await _loadSubscriptions();
      _showSnackBar('Success', 'Added ${newConfigs.length} new servers (${configs.length} total)');
    } catch (e) {
      _showSnackBar('Error', e.toString());
    }
  }

  Future<void> _activateSuggestedSubscription(Subscription subscription) async {
    _showSnackBar('Loading', 'Fetching servers...');
    final service = Provider.of<V2RayService>(context, listen: false);
    try {
      final result = await service.parseSubscriptionUrl(subscription.url, subscriptionId: subscription.id);
      final configs = (result['configs'] as List).cast<V2RayConfig>();
      final subInfo = result['subInfo'] as Map<String, dynamic>?;
      
      if (configs.isEmpty) {
        _showSnackBar('Error', 'No servers found in subscription');
        return;
      }
      
      final existingConfigs = await service.loadConfigs();
      final existingFullConfigs = existingConfigs.map((c) => c.fullConfig).toSet();
      final newConfigs = configs.where((config) => !existingFullConfigs.contains(config.fullConfig)).toList();
      
      if (newConfigs.isEmpty && existingConfigs.isNotEmpty) {
        _showSnackBar('Info', 'All ${configs.length} servers already exist');
        final activatedSub = subscription.copyWith(
          lastUpdate: DateTime.now(),
          configCount: configs.length,
          upload: subInfo?['upload'] as int?,
          download: subInfo?['download'] as int?,
          total: subInfo?['total'] as int?,
          expire: subInfo?['expire'] as DateTime?,
        );
        _subscriptions.add(activatedSub);
        await service.saveSubscriptions(_subscriptions);
        setState(() => _isSuggestedActive = true);
        return;
      }
      
      final allConfigs = [...existingConfigs, ...newConfigs];
      await service.saveConfigs(allConfigs);

      final activatedSub = subscription.copyWith(
        lastUpdate: DateTime.now(),
        configCount: newConfigs.isNotEmpty ? newConfigs.length : configs.length,
        upload: subInfo?['upload'] as int?,
        download: subInfo?['download'] as int?,
        total: subInfo?['total'] as int?,
        expire: subInfo?['expire'] as DateTime?,
      );
      _subscriptions.add(activatedSub);
      await service.saveSubscriptions(_subscriptions);
      setState(() => _isSuggestedActive = true);
      _showSnackBar('Subscription Activated', 'Added ${newConfigs.length} new servers');
    } catch (e) {
      _showSnackBar('Activation Failed', e.toString());
    }
  }

  Future<void> _updateSubscription(Subscription subscription) async {
    final service = Provider.of<V2RayService>(context, listen: false);
    try {
      final result = await service.parseSubscriptionUrl(subscription.url, subscriptionId: subscription.id);
      final configs = (result['configs'] as List).cast<V2RayConfig>();
      final subInfo = result['subInfo'] as Map<String, dynamic>?;
      
      final existingConfigs = await service.loadConfigs();
      final filteredConfigs = existingConfigs.where((config) {
        return config.subscriptionId != subscription.id;
      }).toList();
      final allConfigs = [...filteredConfigs, ...configs];
      await service.saveConfigs(allConfigs);

      final updatedSub = subscription.copyWith(
        lastUpdate: DateTime.now(),
        configCount: configs.length,
        upload: subInfo?['upload'] as int?,
        download: subInfo?['download'] as int?,
        total: subInfo?['total'] as int?,
        expire: subInfo?['expire'] as DateTime?,
      );
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) _subscriptions[index] = updatedSub;
      await service.saveSubscriptions(_subscriptions);
      await _loadSubscriptions();
      _showSnackBar('Updated', 'Updated ${configs.length} servers');
    } catch (e) {
      _showSnackBar('Error', e.toString());
    }
  }

  Future<void> _deleteSubscription(Subscription subscription) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Subscription'),
        content: Text('Are you sure you want to delete "${subscription.name}"?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              _subscriptions.removeWhere((s) => s.id == subscription.id);
              final service = Provider.of<V2RayService>(context, listen: false);
              await service.saveSubscriptions(_subscriptions);
              await _loadSubscriptions();
              _showSnackBar('Deleted', 'Subscription deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

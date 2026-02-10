import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:zedsecure/services/update_checker_service.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zedsecure/widgets/custom_glass_popup.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomGlassPopup(
      title: 'Update Available',
      leadingIcon: CupertinoIcons.arrow_down_circle_fill,
      iconColor: AppTheme.connectedGreen,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Version ${updateInfo.latestVersion}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.connectedGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: ${updateInfo.currentVersion}',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.systemGray,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                updateInfo.releaseNotes,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: _buildButton(
                context: context,
                text: 'Skip',
                onPressed: () async {
                  await UpdateCheckerService.skipVersion(updateInfo.latestVersion);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                isPrimary: false,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                context: context,
                text: 'Update',
                onPressed: () async {
                  final url = Uri.parse(UpdateCheckerService.releasesUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                isPrimary: true,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: CupertinoButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: TextStyle(
                color: AppTheme.systemGray,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isDark,
  }) {
    return Container(
      decoration: AppTheme.futuristicButtonDecoration(
        isPrimary: isPrimary,
        isDark: isDark,
        isDestructive: false,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        borderRadius: BorderRadius.circular(16),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black),
            fontSize: 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

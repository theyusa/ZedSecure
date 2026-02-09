import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:zedsecure/theme/app_theme.dart';

class CustomGlassDialog extends StatefulWidget {
  final String? title;
  final String? content;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final IconData? leadingIcon;
  final Color? iconColor;
  final bool isPrimaryDestructive;
  final bool isDismissible;

  const CustomGlassDialog({
    super.key,
    this.title,
    this.content,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.leadingIcon,
    this.iconColor,
    this.isPrimaryDestructive = false,
    this.isDismissible = true,
  });

  static Future<bool?> show({
    required BuildContext context,
    String? title,
    String? content,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    IconData? leadingIcon,
    Color? iconColor,
    bool isPrimaryDestructive = false,
    bool isDismissible = true,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CustomGlassDialog(
          title: title,
          content: content,
          primaryButtonText: primaryButtonText,
          secondaryButtonText: secondaryButtonText,
          onPrimaryPressed: onPrimaryPressed,
          onSecondaryPressed: onSecondaryPressed,
          leadingIcon: leadingIcon,
          iconColor: iconColor,
          isPrimaryDestructive: isPrimaryDestructive,
          isDismissible: isDismissible,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _DialogAnimation(
          animation: animation,
          isDismissible: isDismissible,
          child: child!,
        );
      },
      );
  }

  @override
  State<CustomGlassDialog> createState() => CustomGlassDialogState();
}

class _DialogAnimation extends StatelessWidget {
  final Animation<double> animation;
  final bool isDismissible;
  final Widget child;

  const _DialogAnimation({
    required this.animation,
    required this.isDismissible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: curvedAnimation.value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * curvedAnimation.value),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: isDismissible ? () => Navigator.pop(context) : null,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}

class CustomGlassDialogState extends State<CustomGlassDialog> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {},
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.95),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (widget.iconColor ?? (widget.isPrimaryDestructive
                                    ? AppTheme.disconnectedRed
                                    : AppTheme.primaryBlue))
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.leadingIcon,
                            color: widget.iconColor ??
                                (widget.isPrimaryDestructive
                                    ? AppTheme.disconnectedRed
                                    : AppTheme.primaryBlue),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (widget.title != null) ...[
                        Text(
                          widget.title!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.content != null) ...[
                        Text(
                          widget.content!,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.primaryButtonText != null || widget.secondaryButtonText != null) ...[
                  const Divider(height: 1, color: Colors.black12),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (widget.secondaryButtonText != null) ...[
                          Expanded(
                            child: _buildButton(
                              text: widget.secondaryButtonText!,
                              onPressed: () {
                                Navigator.pop(context, false);
                                widget.onSecondaryPressed?.call();
                              },
                              isPrimary: false,
                              isDark: isDark,
                            ),
                          ),
                          if (widget.primaryButtonText != null) const SizedBox(width: 12),
                        ],
                        if (widget.primaryButtonText != null)
                          Expanded(
                            child: _buildButton(
                              text: widget.primaryButtonText!,
                              onPressed: () {
                                Navigator.pop(context, true);
                                widget.onPrimaryPressed?.call();
                              },
                              isPrimary: true,
                              isDestructive: widget.isPrimaryDestructive,
                              isDark: isDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    bool isDestructive = false,
    required bool isDark,
  }) {
    final backgroundColor = isPrimary
        ? (isDestructive ? AppTheme.disconnectedRed : AppTheme.primaryBlue)
        : (isDark ? Colors.white12 : Colors.black12);

    final textColor = isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black);

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

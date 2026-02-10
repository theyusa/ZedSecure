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
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: curvedAnimation.value,
          child: Transform.scale(
            scale: 0.85 + (0.15 * curvedAnimation.value),
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
          maxWidth: MediaQuery.of(context).size.width * 0.88,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: AppTheme.futuristicGlassDecoration(
          borderRadius: 32,
          isDark: isDark,
          glowColor: widget.iconColor ?? (widget.isPrimaryDestructive ? AppTheme.disconnectedRed : AppTheme.primaryBlue),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (widget.iconColor ?? (widget.isPrimaryDestructive
                                    ? AppTheme.disconnectedRed
                                    : AppTheme.primaryBlue))
                                .withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (widget.iconColor ?? (widget.isPrimaryDestructive
                                      ? AppTheme.disconnectedRed
                                      : AppTheme.primaryBlue))
                                  .withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            widget.leadingIcon,
                            color: widget.iconColor ??
                                (widget.isPrimaryDestructive
                                    ? AppTheme.disconnectedRed
                                    : AppTheme.primaryBlue),
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (widget.title != null) ...[
                        Text(
                          widget.title!,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.content != null) ...[
                        Text(
                          widget.content!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.primaryButtonText != null || widget.secondaryButtonText != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
    return Container(
      decoration: AppTheme.futuristicButtonDecoration(
        isPrimary: isPrimary,
        isDestructive: isDestructive,
        isDark: isDark,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        borderRadius: BorderRadius.circular(16),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary ? Colors.white : (isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.9)),
            fontSize: 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

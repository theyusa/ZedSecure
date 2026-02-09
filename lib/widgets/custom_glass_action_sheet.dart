import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:zedsecure/theme/app_theme.dart';

class CustomGlassActionSheetItem {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isDefault;
  final TextStyle? textStyle;

  const CustomGlassActionSheetItem({
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.isDefault = false,
    this.textStyle,
  });
}

class CustomGlassActionSheet extends StatefulWidget {
  final String? title;
  final List<CustomGlassActionSheetItem> actions;
  final String? cancelText;
  final VoidCallback? onCancel;
  final bool isDismissible;

  const CustomGlassActionSheet({
    super.key,
    this.title,
    required this.actions,
    this.cancelText,
    this.onCancel,
    this.isDismissible = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required List<CustomGlassActionSheetItem> actions,
    String? cancelText,
    VoidCallback? onCancel,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      isScrollControlled: true,
      enableDrag: isDismissible,
      builder: (context) => CustomGlassActionSheet(
        title: title,
        actions: actions,
        cancelText: cancelText,
        onCancel: onCancel,
        isDismissible: isDismissible,
      ),
    );
  }

  @override
  State<CustomGlassActionSheet> createState() => CustomGlassActionSheetState();
}

class CustomGlassActionSheetState extends State<CustomGlassActionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.isDismissible ? _dismiss : null,
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * (1 - _slideAnimation.value)),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () {},
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              widget.title!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.systemGray,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Divider(height: 1, color: Colors.black12),
                        ],
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: widget.actions.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                            itemBuilder: (context, index) {
                              final action = widget.actions[index];
                              final isSelected = action.isDefault;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _dismiss();
                                    action.onTap?.call();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryBlue.withOpacity(0.08)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        if (action.leading != null) ...[
                                          action.leading!,
                                          const SizedBox(width: 12),
                                        ],
                                        Expanded(
                                          child: Text(
                                            action.title,
                                            style: action.textStyle ??
                                                TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                  color: action.isDestructive
                                                      ? AppTheme.disconnectedRed
                                                      : (isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white : Colors.black)),
                                                ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (action.trailing != null) ...[
                                          const SizedBox(width: 12),
                                          action.trailing!,
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (widget.cancelText != null) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Colors.black12),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _dismiss();
                                widget.onCancel?.call();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Text(
                                  widget.cancelText!,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.systemGray,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

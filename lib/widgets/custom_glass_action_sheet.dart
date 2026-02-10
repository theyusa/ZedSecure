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
  final bool isHeader;
  final TextStyle? textStyle;

  const CustomGlassActionSheetItem({
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.isDefault = false,
    this.isHeader = false,
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
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutExpo,
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
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                decoration: AppTheme.futuristicGlassDecoration(
                  borderRadius: 28,
                  isDark: isDark,
                  glowColor: AppTheme.primaryBlue,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                            child: Text(
                              widget.title!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.systemGray,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                        ],
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: widget.actions.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 2),
                            itemBuilder: (context, index) {
                              final action = widget.actions[index];
                              final isSelected = action.isDefault;

                              if (action.isHeader) {
                                return Container(
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                  child: Text(
                                    action.title.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.systemGray.withOpacity(0.8),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                );
                              }

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _dismiss();
                                    action.onTap?.call();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: isSelected 
                                          ? AppTheme.primaryBlue.withOpacity(0.1)
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        if (action.leading != null)
                                          Opacity(
                                            opacity: isSelected ? 1.0 : 0.7,
                                            child: action.leading!,
                                          ),
                                        if (action.leading != null)
                                          const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            action.title,
                                            style: action.textStyle ??
                                                TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                  color: action.isDestructive
                                                      ? AppTheme.disconnectedRed
                                                      : (isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white : Colors.black87)),
                                                ),
                                            textAlign: action.leading == null ? TextAlign.center : TextAlign.left,
                                          ),
                                        ),
                                        if (action.trailing != null)
                                          const SizedBox(width: 12),
                                        if (action.trailing != null)
                                          action.trailing!,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (widget.cancelText != null) ...[
                          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _dismiss();
                                widget.onCancel?.call();
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                child: Text(
                                  widget.cancelText!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.systemGray,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
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

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
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                decoration: AppTheme.futuristicGlassDecoration(
                  borderRadius: 36,
                  isDark: isDark,
                  glowColor: AppTheme.primaryBlue,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark 
                            ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
                            : [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.1)],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                              child: Text(
                                widget.title!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.systemGray,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark 
                                    ? [Colors.white12, Colors.transparent, Colors.white12]
                                    : [Colors.black12, Colors.transparent, Colors.black12],
                                ),
                              ),
                            ),
                          ],
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: widget.actions.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 4),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: [
                                                  AppTheme.primaryBlue.withOpacity(0.18),
                                                  AppTheme.primaryBlue.withOpacity(0.04),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        border: isSelected ? Border.all(
                                          color: AppTheme.primaryBlue.withOpacity(0.2),
                                          width: 1,
                                        ) : null,
                                      ),
                                      child: Row(
                                        children: [
                                          if (action.leading != null)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: isSelected ? null : BoxDecoration(
                                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Opacity(
                                                opacity: isSelected ? 1.0 : 0.8,
                                                child: action.leading!,
                                              ),
                                            ),
                                          if (action.leading != null)
                                            const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              action.title,
                                              style: action.textStyle ??
                                                  TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                    color: action.isDestructive
                                                        ? AppTheme.disconnectedRed
                                                        : (isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white : Colors.black87)),
                                                    letterSpacing: -0.3,
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
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark 
                                    ? [Colors.white12, Colors.transparent, Colors.white12]
                                    : [Colors.black12, Colors.transparent, Colors.black12],
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _dismiss();
                                  widget.onCancel?.call();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  child: Text(
                                    widget.cancelText!,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.systemGray,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                decoration: AppTheme.futuristicGlassDecoration(
                  borderRadius: 36,
                  isDark: isDark,
                  glowColor: AppTheme.primaryBlue,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark 
                            ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
                            : [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.1)],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                              child: Text(
                                widget.title!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.systemGray,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark 
                                    ? [Colors.white12, Colors.transparent, Colors.white12]
                                    : [Colors.black12, Colors.transparent, Colors.black12],
                                ),
                              ),
                            ),
                          ],
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: widget.actions.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 4),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                AppTheme.primaryBlue.withOpacity(0.18),
                                                AppTheme.primaryBlue.withOpacity(0.04),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      border: isSelected ? Border.all(
                                        color: AppTheme.primaryBlue.withOpacity(0.2),
                                        width: 1,
                                      ) : null,
                                    ),
                                    child: Row(
                                      children: [
                                        if (action.leading != null)
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: isSelected ? null : BoxDecoration(
                                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Opacity(
                                              opacity: isSelected ? 1.0 : 0.8,
                                              child: action.leading!,
                                            ),
                                          ),
                                        if (action.leading != null)
                                          const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            action.title,
                                            style: action.textStyle ??
                                                TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: action.isDestructive
                                                      ? AppTheme.disconnectedRed
                                                      : (isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white : Colors.black87)),
                                                  letterSpacing: -0.3,
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
                          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _dismiss();
                                widget.onCancel?.call();
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                child: Text(
                                  widget.cancelText!,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.systemGray,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
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

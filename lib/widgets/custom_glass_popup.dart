import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:zedsecure/theme/app_theme.dart';

class CustomGlassPopup extends StatefulWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final double? width;
  final double? maxWidth;
  final double? maxHeight;
  final bool isDismissible;
  final IconData? leadingIcon;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const CustomGlassPopup({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.width,
    this.maxWidth = 400,
    this.maxHeight,
    this.isDismissible = true,
    this.leadingIcon,
    this.iconColor,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    double? width,
    double? maxWidth,
    double? maxHeight,
    bool isDismissible = true,
    IconData? leadingIcon,
    Color? iconColor,
    EdgeInsetsGeometry? padding,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CustomGlassPopup(
          title: title,
          content: content,
          actions: actions,
          width: width,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          isDismissible: isDismissible,
          leadingIcon: leadingIcon,
          iconColor: iconColor,
          padding: padding,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _PopupAnimation(
          animation: animation,
          isDismissible: isDismissible,
          child: child,
        );
      },
    );
  }

  @override
  State<CustomGlassPopup> createState() => CustomGlassPopupState();
}

class _PopupAnimation extends StatelessWidget {
  final Animation<double> animation;
  final bool isDismissible;
  final Widget child;

  const _PopupAnimation({
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

class CustomGlassPopupState extends State<CustomGlassPopup> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final popupWidth = widget.width ?? (screenWidth * 0.9);

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: widget.maxWidth != null && popupWidth > widget.maxWidth!
            ? widget.maxWidth
            : popupWidth,
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth ?? 380,
          maxHeight: widget.maxHeight ?? MediaQuery.of(context).size.height * 0.75,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: AppTheme.futuristicGlassDecoration(
          borderRadius: 28,
          isDark: isDark,
          glowColor: widget.iconColor ?? AppTheme.primaryBlue,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.title != null || widget.leadingIcon != null) ...[
                      Row(
                        children: [
                          if (widget.leadingIcon != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (widget.iconColor ?? AppTheme.primaryBlue).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.leadingIcon,
                                color: widget.iconColor ?? AppTheme.primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              widget.title ?? '',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 16),
                    ],
                    Flexible(child: widget.content),
                    if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      ...widget.actions!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

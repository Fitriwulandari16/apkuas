import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final Color? backgroundColor;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 600;
        
        Widget content = child;
        if (useSafeArea) {
          content = SafeArea(child: content);
        }

        return Container(
          color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

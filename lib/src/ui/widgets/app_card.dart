import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const AppCard({
    super.key,
    required this.child,
    required this.radius,
    this.onTap,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.surface.withOpacity(0.20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,

            // ❌ Border kaldırıldı (beyaz çizgi hissi buradan geliyordu)
            // border: Border.all(color: Theme.of(context).dividerColor),

            // ✅ Hafif shadow ile “kart birleşik” hissi düzeldi
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}

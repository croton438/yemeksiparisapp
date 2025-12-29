import 'package:flutter/material.dart';

class Topbar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;

  const Topbar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: leading == null ? const SizedBox.shrink() : Center(child: leading),
            ),
            Expanded(
              child: centerTitle
                  ? Center(child: titleWidget)
                  : Align(alignment: Alignment.centerLeft, child: titleWidget),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: trailing == null ? const SizedBox.shrink() : Center(child: trailing),
            ),
          ],
        ),
      ),
    );
  }
}

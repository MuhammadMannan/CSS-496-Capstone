import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'main_logo.dart';

class FlockAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final double height;
  final Widget? trailing;

  const FlockAppBar({
    this.showBackButton = false,
    this.height = 80,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      centerTitle: true,
      backgroundColor: ShadTheme.of(context).colorScheme.background,
      elevation: 0,
      toolbarHeight: height,
      title: const MainLogo(width: 160),
      actions: trailing != null ? [Padding(padding: const EdgeInsets.only(right: 12), child: trailing!)] : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

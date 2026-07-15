import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../layout/root_layout.dart';

class SubZillaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SubZillaAppBar({this.trailing, super.key});

  final Widget? trailing;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: rootScaffoldKey.currentState?.hasDrawer ?? false
          ? IconButton(
              icon: const Icon(CupertinoIcons.bars),
              onPressed: () {
                rootScaffoldKey.currentState?.openDrawer();
              },
            )
          : null,
      middle: Text('settings.app_name'.tr()),
      trailing: trailing,
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:subs_tracker/layout/root_layout.dart';

class SubZillaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SubZillaAppBar({this.trailing, super.key});

  final Widget? trailing;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      automaticallyImplyLeading: true,
      leading: rootScaffoldKey.currentState?.hasDrawer == true
          ? IconButton(
              icon: Icon(CupertinoIcons.bars),
              onPressed: () {
                rootScaffoldKey.currentState?.openDrawer();
              },
            )
          : null,
      middle: Text("settings.app_name".tr()),
      trailing: trailing,
    );
  }
}

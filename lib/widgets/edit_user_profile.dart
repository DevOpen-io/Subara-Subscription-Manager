import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subs_tracker/providers/settings_controller.dart';
import 'package:subs_tracker/widgets/action_text_form_field.dart';

class EditUserProfileDialog extends ConsumerStatefulWidget {
  const EditUserProfileDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChooseOrEditPPState();
}

class _ChooseOrEditPPState extends ConsumerState<EditUserProfileDialog> {
  @override
  Widget build(BuildContext context) {
    final settingsController = ref.watch(settingsControllerProvider);

    return AlertDialog.adaptive(
      title: Text("intro.edit_picture".tr()),
      content: settingsController.when(
        error: (e, st) => Center(child: Text('Error: $e')),
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        data: (slice) => Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 128,
                backgroundImage: slice.profilePicture != null
                    ? MemoryImage(slice.profilePicture!) as ImageProvider
                    : const AssetImage('assets/pp.gif'),
                backgroundColor: Colors.grey.shade200,
              ),
              const Divider(height: 32),
              ActionTextFormField(
                labelText: "intro.username_label".tr(),
                initialValue: slice.userName ?? "",
                onSave: (newUserName) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateUserName(newUserName);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("intro.username_saved".tr())),
                  );
                },
              ),
              const SizedBox(height: 8),
              ActionTextFormField(
                labelText: "intro.email_label".tr(),
                initialValue: slice.email ?? "",
                onSave: (newEmail) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateUserEmail(newEmail);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("intro.email_saved".tr())));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

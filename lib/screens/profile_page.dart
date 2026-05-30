import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_gravatar_fetch/simple_gravatar_fetch.dart';
import 'package:subs_tracker/providers/settings_controller.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilePicture = useState<Uint8List?>(null);
    final isGravatarLoading = useState<bool>(false);
    final emailController = useTextEditingController();

    Future<void> pickImage() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes();
        profilePicture.value = bytes;
        ref.read(settingsControllerProvider.notifier).updateProfilePicture(bytes);
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32.0, 60.0, 32.0, 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Profile Image Preview
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Theme.of(context).cardColor,
                backgroundImage: profilePicture.value != null
                    ? MemoryImage(profilePicture.value!)
                    : null,
                child: profilePicture.value == null
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: 80,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.5),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 40),

            // Added Title for consistency
            Text(
              'intro.profile_title'.tr(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Email Input
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'intro.email_label'.tr(),
                  hintText: 'intro.email_hint'.tr(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  // Optional: Save email in real-time if needed
                },
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text('intro.gallery_btn'.tr()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isGravatarLoading.value
                        ? null
                        : () async {
                            if (emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "intro.error_email_empty".tr(),
                                  ),
                                ),
                              );
                              return;
                            }

                            isGravatarLoading.value = true;

                            try {
                              final Uint8List? imageBytes = await getGravatar(
                                emailController.text,
                                size: 500,
                              );

                              if (imageBytes != null) {
                                profilePicture.value = imageBytes;
                                ref.read(settingsControllerProvider.notifier).updateProfilePicture(imageBytes);
                                ref.read(settingsControllerProvider.notifier).updateUserEmail(emailController.text);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "intro.error_gravatar".tr(),
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "intro.error_image".tr(args: [e.toString()]),
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                isGravatarLoading.value = false;
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    icon: isGravatarLoading.value
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(isGravatarLoading.value ? 'intro.loading'.tr() : 'intro.gravatar_btn'.tr()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'intro.profile_desc'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

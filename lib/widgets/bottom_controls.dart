import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({
    super.key,
    required this.currentPage,
    required this.pageController,
    required this.finishOnboarding,
    required this.totalPages,
  });

  final ValueNotifier<int> currentPage;
  final PageController pageController;
  final VoidCallback finishOnboarding;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    if (currentPage.value == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentPage.value > 0)
            TextButton(
              onPressed: () {
                pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text('common.back'.tr()),
            )
          else
            const SizedBox(width: 64),
          if (currentPage.value < totalPages - 1)
            TextButton(
              onPressed: () {
                pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text('common.next'.tr()),
            )
          else
            ElevatedButton(
              onPressed: finishOnboarding,
              child: Text('common.finish'.tr()),
            ),
        ],
      ),
    );
  }
}

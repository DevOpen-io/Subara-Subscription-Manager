import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/subs_controller.dart';

// Create a testable subclass that bypasses persistence
class TestSubsController extends SubsController {
  @override
  Future<List<SubSlice>> build() async {
    // Skip persistence and just return empty list initially
    // We still want to trigger scheduleNotification if needed, but for unit test we might want to verify it's called.
    return []; 
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock Notification Channel to prevent crash
    const notificationChannel =
        MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      notificationChannel,
      (methodCall) async {
        return null;
      },
    );
  });

  test('SubsController adds a slice and updates state', () async {
    final container = ProviderContainer(
      overrides: [
        subsControllerProvider.overrideWith(TestSubsController.new),
      ],
    );

    // Read initial state
    final initial = await container.read(subsControllerProvider.future);
    expect(initial, isEmpty);

    // Add a slice
    final slice = SubSlice(
      name: 'Netflix',
      amount: 15,
      color: 0xFF000000,
      startDate: DateTime.now(),
    );

    container.read(subsControllerProvider.notifier).addSlice(slice);

    // Verify state updated
    final updated = await container.read(subsControllerProvider.future);
    expect(updated, hasLength(1));
    expect(updated.first.name, 'Netflix');
    expect(updated.first.frequency, Frequency.monthly);
  });

  test('SubsController removes a slice', () async {
    final container = ProviderContainer(
      overrides: [
        subsControllerProvider.overrideWith(TestSubsController.new),
      ],
    );

    final slice = SubSlice(
      name: 'Spotify',
      amount: 10,
      color: 0xFF000000,
      startDate: DateTime.now(),
    );

    // Wait for initialization
    await container.read(subsControllerProvider.future);

    // Add then remove
    container.read(subsControllerProvider.notifier).addSlice(slice);
    
    // Verify add worked
    final added = await container.read(subsControllerProvider.future);
    expect(added, hasLength(1));
    
    container.read(subsControllerProvider.notifier).removeAt(0);
    
    final updated = await container.read(subsControllerProvider.future);
    expect(updated, isEmpty);
  });
}

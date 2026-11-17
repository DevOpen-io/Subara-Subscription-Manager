import 'package:file_selector/file_selector.dart';

/// Lets the user pick a JSON backup file. Returns its contents, or null if
/// nothing was picked.
Future<String?> pickBackupFile() async {
  const jsonType = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );
  final picked = await openFile(acceptedTypeGroups: [jsonType]);
  return picked?.readAsString();
}

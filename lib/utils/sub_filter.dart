import '../models/sub_slice.dart';

/// Search text plus status filter for the home list. An empty [statuses]
/// means every status.
class SubFilter {
  const SubFilter({this.query = '', this.statuses = const {}});

  final String query;
  final Set<SubStatus> statuses;

  bool get isActive => query.trim().isNotEmpty || statuses.isNotEmpty;

  SubFilter copyWith({String? query, Set<SubStatus>? statuses}) => SubFilter(
    query: query ?? this.query,
    statuses: statuses ?? this.statuses,
  );

  List<SubSlice> apply(List<SubSlice> subs) {
    final q = _fold(query.trim());
    return [
      for (final s in subs)
        if ((statuses.isEmpty || statuses.contains(s.status)) &&
            (q.isEmpty ||
                [
                  s.name,
                  s.category,
                  s.brand?.category,
                  s.note,
                ].any((f) => f != null && _fold(f).contains(q))))
          s,
    ];
  }
}

/// Lower-cases and maps Turkish İ/ı/I to i, so "İCLOUD" finds "iCloud".
String _fold(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('i̇', 'i');

import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/brand.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/utils/sub_filter.dart';

SubSlice _sub(
  String name, {
  SubStatus status = SubStatus.active,
  String? category,
  String? note,
  Brand? brand,
}) => SubSlice(
  id: name,
  name: name,
  amount: 1,
  color: 0,
  startDate: DateTime(2026),
  status: status,
  category: category,
  note: note,
  brand: brand,
);

void main() {
  final subs = [
    _sub(
      'Netflix',
      brand: const Brand(text: 'Netflix', category: 'Streaming'),
    ),
    _sub('Spotify', status: SubStatus.paused, category: 'Music'),
    _sub('Gym', status: SubStatus.cancelled, note: 'Spor salonu'),
    _sub('iCloud', status: SubStatus.freeTrial),
  ];

  List<String> names(SubFilter f) => f.apply(subs).map((s) => s.name).toList();

  test('empty filter keeps everything in order', () {
    expect(const SubFilter().isActive, isFalse);
    expect(names(const SubFilter()), ['Netflix', 'Spotify', 'Gym', 'iCloud']);
  });

  test('query matches name, category, brand category and note', () {
    expect(names(const SubFilter(query: 'net')), ['Netflix']);
    expect(names(const SubFilter(query: 'music')), ['Spotify']);
    expect(names(const SubFilter(query: 'STREAM')), ['Netflix']);
    expect(names(const SubFilter(query: 'salon')), ['Gym']);
    expect(names(const SubFilter(query: '  ')), hasLength(4));
  });

  test('query ignores Turkish dotted/dotless i differences', () {
    expect(names(const SubFilter(query: 'İCLOUD')), ['iCloud']);
    expect(names(const SubFilter(query: 'spor salonu')), ['Gym']);
  });

  test('status filter', () {
    expect(
      names(const SubFilter(statuses: {SubStatus.active, SubStatus.freeTrial})),
      ['Netflix', 'iCloud'],
    );
    expect(
      names(const SubFilter(query: 'i', statuses: {SubStatus.freeTrial})),
      ['iCloud'],
    );
    expect(const SubFilter(statuses: {SubStatus.paused}).isActive, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/utils/manage_url.dart';

void main() {
  test('adds https to a bare domain', () {
    expect(
      normalizeManageUrl('netflix.com/account'),
      'https://netflix.com/account',
    );
  });

  test('keeps http and https links', () {
    expect(normalizeManageUrl(' https://a.io/x '), 'https://a.io/x');
    expect(normalizeManageUrl('http://a.io'), 'http://a.io');
  });

  test('rejects other schemes and junk', () {
    expect(normalizeManageUrl('javascript:alert(1)'), isNull);
    expect(normalizeManageUrl('file:///etc/passwd'), isNull);
    expect(normalizeManageUrl('intent://x#Intent;end'), isNull);
    expect(normalizeManageUrl('not a url'), isNull);
    expect(normalizeManageUrl(''), isNull);
  });

  test('safeManageUri only accepts http(s) with a host', () {
    expect(safeManageUri('https://a.io')?.host, 'a.io');
    expect(safeManageUri('tel:123'), isNull);
    expect(safeManageUri(null), isNull);
  });
}

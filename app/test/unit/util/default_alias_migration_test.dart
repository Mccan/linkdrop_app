import 'package:test/test.dart';
import 'package:linkdrop_app/util/default_alias.dart';

void main() {
  test('Should derive deterministic alias from show token', () {
    expect(buildDefaultAlias('abcd-efgh'), 'Device-ABCD');
  });

  test('Should pad short token to four chars', () {
    expect(buildDefaultAlias('a'), 'Device-A000');
  });

  test('Should fallback to Device-0000 for empty token', () {
    expect(buildDefaultAlias(''), 'Device-0000');
  });
}

import 'package:linkdrop_app/util/local_alias.dart';
import 'package:test/test.dart';

void main() {
  test('Should keep custom alias when alias is modified', () {
    expect(
      resolveEffectiveLocalAlias(
        storedAlias: 'custom-name',
        isAliasModified: true,
      ),
      'custom-name',
    );
  });

  test('Should keep stored alias when alias is not modified', () {
    expect(
      resolveEffectiveLocalAlias(
        storedAlias: 'Device-ABCD',
        isAliasModified: false,
      ),
      'Device-ABCD',
    );
  });

  test('Should display ip suffix when not modified', () {
    expect(
      resolveLocalDeviceDisplayName(
        storedAlias: 'Device-ABCD',
        isAliasModified: false,
        ip: '192.168.0.103',
      ),
      '103（我）',
    );
  });

  test('Should display stored alias when ip is missing', () {
    expect(
      resolveLocalDeviceDisplayName(
        storedAlias: 'Device-ABCD',
        isAliasModified: false,
        ip: null,
      ),
      'Device-ABCD',
    );
  });

  test('Should use ip suffix as alias editor initial value when not modified', () {
    expect(
      resolveLocalAliasEditorInitialValue(
        storedAlias: 'Device-ABCD',
        isAliasModified: false,
        ip: '192.168.0.103',
      ),
      '103（我）',
    );
  });
}

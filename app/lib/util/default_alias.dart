const defaultAliasPrefix = 'Device-';

String buildDefaultAlias(String showToken) {
  final compactToken = showToken.replaceAll('-', '').toUpperCase();
  if (compactToken.isEmpty) {
    return '${defaultAliasPrefix}0000';
  }

  final suffix = compactToken.length >= 4 ? compactToken.substring(0, 4) : compactToken.padRight(4, '0');
  return '$defaultAliasPrefix$suffix';
}

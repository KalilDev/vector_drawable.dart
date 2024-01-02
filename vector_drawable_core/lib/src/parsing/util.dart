import '../model/color.dart';
export '../parsing_and_serializing_commons.dart';

T? parseEnum<T extends Enum>(String text, List<T> values) =>
    values.cast<T?>().singleWhere(
          (e) => e!.name == text,
          orElse: () => null,
        );
bool? parseBool(String str) => str == 'true'
    ? true
    : str == 'false'
        ? false
        : null;

VectorColor parseHexColor(String hex) {
  if (hex[0] != '#') {
    throw StateError('not hex');
  }
  var str = hex.substring(1);
  if (str.length == 3) {
    str = 'FF${str[0]}${str[0]}${str[1]}${str[1]}${str[2]}${str[2]}';
  } else if (str.length == 4) {
    str =
        '${str[0]}${str[0]}${str[1]}${str[1]}${str[2]}${str[2]}${str[3]}${str[3]}';
  } else if (str.length == 6) {
    str = 'FF$str';
  } else if (str.length != 8) {
    throw StateError('notHex');
  }
  final a = str.substring(0, 2);
  final r = str.substring(2, 4);
  final g = str.substring(4, 6);
  final b = str.substring(6, 8);
  return VectorColor.components(
    int.parse(r, radix: 16),
    int.parse(g, radix: 16),
    int.parse(b, radix: 16),
    int.parse(a, radix: 16),
  );
}

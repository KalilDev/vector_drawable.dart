import 'package:xml/xml.dart';

class ParseException implements Exception {
  final XmlNode node;
  final Object? message;

  ParseException(this.node, this.message);
}

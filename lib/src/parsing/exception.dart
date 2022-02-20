import 'package:xml/xml.dart';

class ParseException implements Exception {
  final XmlElement node;
  final Object? message;

  ParseException(this.node, this.message);
  String toString() => '$runtimeType: ${node.name} ${message}.\n$node';
}

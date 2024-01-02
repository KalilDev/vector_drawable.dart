import 'package:xml/xml.dart';

const kAndroidXmlNamespace = 'http://schemas.android.com/apk/res/android';
const kAaptXmlNamespace = 'http://schemas.android.com/aapt';

extension ObjectMapE<T> on T {
  R mapSelfTo<R>(R Function(T) fn) => fn(this);
}

extension AndroidXmlElementE on XmlElement {
  String? getAndroidAttribute(String name) =>
      getAttribute(name, namespace: kAndroidXmlNamespace);
}

@Deprecated("TODO")
Never throwUnimplemented([String? message]) =>
    throw UnimplementedError(message);

bool _isAaptAttr(XmlName name) =>
    name.namespaceUri == kAaptXmlNamespace && name.local == 'attr';

Iterable<XmlElement> _whereIsNotInlineResource(Iterable<XmlElement> elements) =>
    elements.where((e) => !_isAaptAttr(e.name));

extension WhereIsNotInlineResourceXmlElementE on Iterable<XmlElement> {
  Iterable<XmlElement> whereIsNotInlineResource() =>
      _whereIsNotInlineResource(this);
}

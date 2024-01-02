import 'style.dart';

class VectorNullable<T extends Object> {
  final bool hasValue;
  final T? value;
  const VectorNullable.value$(this.value) : hasValue = true;
  const VectorNullable.null$()
      : hasValue = false,
        value = null;
}

abstract class IHaveProperties {
  List<VectorProperty<void>> properties();
}

abstract class IHaveDiagnosticsChildren {
  List<VectorDiagnosticsNode> diagnosticsChildren();
}

String fastRuntimeType(Object self, String runtimeType) {
  assert(self.runtimeType.toString() == runtimeType);
  return runtimeType;
}

abstract class VectorDiagnosticable implements IHaveProperties {
  const VectorDiagnosticable();
  String toStringShort() => runtimeType.toString();
  @override
  List<VectorProperty<void>> properties() => [];

  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      VectorDiagnosticableNode<VectorDiagnosticable>(name, this);
}

class VectorDiagnosticableNode<T extends VectorDiagnosticable>
    implements VectorDiagnosticsNode {
  final String? name;
  final T obj;

  VectorDiagnosticableNode(this.name, this.obj);

  @override
  String describeSelfShort() => name ?? obj.toStringShort();
  @override
  List<VectorDiagnosticsNode> getChildren() => [];
  @override
  List<VectorProperty<void>> getProperties() => obj.properties();

  @override
  Object? get value => obj;
}

mixin VectorDiagnosticableMixin implements VectorDiagnosticable {
  @override
  String toStringShort() => runtimeType.toString();
  @override
  List<VectorProperty<void>> properties() => [];
  @override
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      VectorDiagnosticableNode<VectorDiagnosticable>(name, this);
}

abstract class VectorDiagnosticsNode {
  const VectorDiagnosticsNode();
  String describeSelfShort();
  List<VectorDiagnosticsNode> getChildren();
  List<VectorProperty<void>> getProperties() => [];
  Object? get value;
}

class VectorProperty<T extends Object> extends VectorDiagnosticsNode {
  final String name;
  final T value;
  final T? defaultValue;

  const VectorProperty(this.name, this.value, {this.defaultValue});

  @override
  String describeSelfShort() => name;

  @override
  List<VectorDiagnosticsNode> getChildren() => [];
}

typedef VectorDoubleProperty = VectorProperty<double>;

class VectorNullableProperty<T extends Object>
    extends VectorProperty<VectorNullable<T>> {
  const VectorNullableProperty._raw(String name, VectorNullable<T> value,
      {VectorNullable<T>? defaultValue})
      : super(name, value, defaultValue: defaultValue);
  factory VectorNullableProperty(String name, T? value) =>
      VectorNullableProperty._raw(
          name,
          value == null
              ? const VectorNullable.null$()
              : VectorNullable.value$(value));
  factory VectorNullableProperty.withDefault(String name, T? value,
          {required T defaultValue}) =>
      VectorNullableProperty._raw(
          name,
          value == null
              ? const VectorNullable.null$()
              : VectorNullable.value$(value),
          defaultValue: VectorNullable.value$(defaultValue));
}

class VectorStyleableProperty<T extends Object>
    extends VectorProperty<StyleOr<T>> {
  const VectorStyleableProperty(String name, StyleOr<T> value)
      : super(name, value);
  factory VectorStyleableProperty.withDefault(String name, StyleOr<T> value,
          {T? defaultValue}) =>
      VectorStyleableProperty.rawWithDefault(name, value,
          defaultValue:
              defaultValue == null ? null : StyleOr.value(defaultValue));
  const VectorStyleableProperty.rawWithDefault(String name, StyleOr<T> value,
      {StyleOr<T>? defaultValue})
      : super(name, value, defaultValue: defaultValue);
}

class VectorEnumProperty<T extends Enum> extends VectorProperty<T> {
  const VectorEnumProperty(String name, T value, {T? defaultValue})
      : super(name, value, defaultValue: defaultValue);
}

class VectorFlagProperty extends VectorProperty<bool> {
  const VectorFlagProperty(String name,
      {required bool value, bool? defaultValue, this.ifTrue})
      : super(name, value, defaultValue: defaultValue);
  final String? ifTrue;
}

class VectorDiagnosticableTree extends VectorDiagnosticable
    implements IHaveDiagnosticsChildren {
  @override
  List<VectorDiagnosticsNode> diagnosticsChildren() => [];
  @override
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      VectorDiagnosticableTreeNode<VectorDiagnosticableTree>(name, this);
}

class VectorDiagnosticableTreeNode<T extends VectorDiagnosticableTree>
    implements VectorDiagnosticsNode {
  final String? name;
  final T obj;

  VectorDiagnosticableTreeNode(this.name, this.obj);

  @override
  String describeSelfShort() => name ?? obj.toStringShort();
  @override
  List<VectorDiagnosticsNode> getChildren() => obj.diagnosticsChildren();
  @override
  List<VectorProperty<void>> getProperties() => obj.properties();

  @override
  Object? get value => obj;
}

mixin VectorDiagnosticableTreeMixin implements VectorDiagnosticableTree {
  @override
  String toStringShort() => runtimeType.toString();

  @override
  List<VectorProperty<void>> properties() => [];

  @override
  List<VectorDiagnosticsNode> diagnosticsChildren() => [];
  @override
  VectorDiagnosticsNode toDiagnosticsNode([String? name]) =>
      VectorDiagnosticableTreeNode<VectorDiagnosticableTree>(name, this);
}

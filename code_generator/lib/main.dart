import 'dart:async';
import 'dart:io';

import 'package:code_generator/sorted_animated_list/controller.dart';
import 'package:code_generator/sorted_animated_list/widget.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:path/path.dart' as p;
import 'package:value_notifier/value_notifier.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:xml/xml.dart';
import 'package:vector_drawable/src/visiting/codegen.dart';
import 'package:vector_drawable/src/visiting/async_resolver.dart';
import 'package:file_picker/file_picker.dart' as picker;

void main() {
  runPlatformThemedApp(
    const MyApp(),
    initialOrFallback: () => const PlatformPalette.fallback(
      primaryColor: Color(0xDEADBEEF),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InheritedControllerInjector(
      factory: (_) => ResourceController(null, [], {}),
      child: MD3Themes(
        monetThemeForFallbackPalette: MonetTheme.baseline3p,
        builder: (context, light, dark) => MaterialApp(
          title: 'Resource code generator',
          theme: light,
          darkTheme: dark,
          home: const MyHomePage(),
        ),
      ),
    );
  }
}

class _ListEntranceTransition extends StatelessWidget {
  const _ListEntranceTransition({
    Key? key,
    required this.animation,
    required this.child,
  }) : super(key: key);
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Interval(2 / 3, 1),
          ),
          child: child,
        ),
      );
}

class _NamespaceDialog extends StatefulWidget {
  const _NamespaceDialog({Key? key}) : super(key: key);

  @override
  __NamespaceDialogState createState() => __NamespaceDialogState();
}

class __NamespaceDialogState extends State<_NamespaceDialog> {
  String namespace = '';
  Directory? root;

  void _pop(BuildContext context) {
    Navigator.of(context).pop<MapEntry<String, Directory>>(null);
  }

  void _popResult(BuildContext context) {
    Navigator.of(context)
        .pop<MapEntry<String, Directory>>(MapEntry(namespace, root!));
  }

  void _setNamespace(String value) => setState(() => namespace = value);
  void _setRoot(String value) => setState(() => root = Directory(value));

  bool get _canPopResult => namespace.isNotEmpty && root != null;

  @override
  Widget build(BuildContext context) => MD3BasicDialog(
        title: Text('Adicionar namespace'),
        icon: Icon(Icons.developer_board),
        content: Column(
          children: [
            _TextField(
              value: namespace,
              onChange: _setNamespace,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                icon: Icon(null),
                labelText: 'Nome',
              ),
            ),
            _DirectoryField(
              path: root?.path ?? Directory.current.path,
              onChange: _setRoot,
              decoration: InputDecoration(
                filled: true,
                icon: Icon(null),
                labelText: 'Pasta',
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => _pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: _canPopResult ? () => _popResult(context) : null,
            child: Text('Salvar'),
          ),
        ],
      );
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  void _showRootDialog(BuildContext context) {
    final controller =
        InheritedController.get<ResourceController>(context).unwrap;
    picker.FilePicker.platform
        .getDirectoryPath()
        .then((path) => path == null ? null : Directory(path))
        .then((e) {
      print(e);
      e != null ? controller.setRootDir(e) : null;
    });
  }

  void _showNamespaceDialog(BuildContext context) {
    final controller =
        InheritedController.get<ResourceController>(context).unwrap;
    showDialog(context: context, builder: (_) => _NamespaceDialog()).then(
      (entry) => entry == null
          ? null
          : controller.addNamespace(entry.key, entry.value),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller =
        InheritedController.get<ResourceController>(context).unwrap;
    picker.FilePicker.platform
        .pickFiles(
          initialDirectory: controller.rootDir.value?.path,
          allowedExtensions: ['.xml'],
          allowMultiple: true,
        )
        .then((result) =>
            result == null ? null : result.files.map((e) => File(e.path!)))
        .then((files) => files == null ? null : controller.addFiles(files));
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        InheritedController.of<ResourceController>(context).unwrap;
    return MD3AdaptativeScaffold(
      appBar: MD3CenterAlignedAppBar(
        title: Text('Resource code generator'),
        trailing: _SaveButton(
          toBeSaved: controller.formattedGeneratedCode,
          snackbarContent: Text('O código para os resources foi copiado!'),
        ),
      ),
      body: controller.rootDir
          .map(
            (root) => root == null
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_rounded, size: 80),
                          Text('Não há um diretorio base dos recursos!'),
                          FilledButton(
                            onPressed: () => _showRootDialog(context),
                            child: Text('Adicionar'),
                          )
                        ]),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _DirectoryField(
                          decoration: InputDecoration(
                            filled: true,
                            icon: Icon(Icons.folder),
                            labelText: 'Base dos recusos',
                            suffixIcon: IconButton(
                              onPressed: () => controller.setRootDir(null),
                              icon: Icon(Icons.delete_outline_outlined),
                            ),
                          ),
                          path: root.path,
                          onChange: (path) =>
                              controller.setRootDir(Directory(path)),
                        ),
                      ),
                      SliverSortedAnimatedList<NamespaceController>(
                        controller: controller.namespacesController.unwrap,
                        itemBuilder: (context, namespace, anim) =>
                            _ListEntranceTransition(
                          animation: anim,
                          child: _NamespaceWidget(namespace: namespace.handle),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Center(
                          child: FilledButton.icon(
                            onPressed: () => _showNamespaceDialog(context),
                            icon: Icon(Icons.add),
                            label: Text('Adicionar namespace'),
                          ),
                        ),
                      ),
                      SliverSortedAnimatedList<FileController>(
                        controller: controller.avdFilesController.unwrap,
                        itemBuilder: (context, file, anim) =>
                            _ListEntranceTransition(
                          animation: anim,
                          child: _FileWidget(file: file.handle),
                        ),
                      ),
                    ],
                  ),
          )
          .build(),
      floatingActionButton: controller.rootDir
          .map((dir) => dir != null)
          .map((hasRoot) => hasRoot
              ? MD3FloatingActionButton.large(
                  onPressed: () => _showAddDialog(context),
                  child: const Icon(Icons.add),
                )
              : const SizedBox())
          .build(),
    );
  }
}

class _NamespaceWidget extends StatelessWidget {
  const _NamespaceWidget({
    Key? key,
    required this.namespace,
  }) : super(key: key);
  final ControllerHandle<NamespaceController> namespace;

  @override
  Widget build(BuildContext context) => OutlinedCard(
        key: ObjectKey(namespace),
        style: CardStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        child: Column(
          children: [
            namespace.unwrap.name
                .map(
                  (name) => _TextField(
                    value: name,
                    onSubmit: namespace.unwrap.setName,
                    decoration: InputDecoration(
                      filled: true,
                      icon: Icon(null),
                      labelText: 'Nome do namespace',
                    ),
                  ),
                )
                .build(),
            namespace.unwrap.root
                .map(
                  (root) => _DirectoryField(
                    decoration: InputDecoration(
                      filled: true,
                      icon: Icon(Icons.folder),
                      labelText: 'Base do namespace',
                    ),
                    path: root.path,
                    onChange: (path) =>
                        namespace.unwrap.setRoot(Directory(path)),
                  ),
                )
                .build()
          ],
        ),
      );
}

class _DirectoryField extends StatelessWidget {
  const _DirectoryField({
    Key? key,
    required this.path,
    required this.onChange,
    this.decoration,
  }) : super(key: key);
  final String path;
  final ValueChanged<String> onChange;
  final InputDecoration? decoration;
  void _showFilesystemDialog(BuildContext context) {
    picker.FilePicker.platform
        .getDirectoryPath()
        .then((e) => e == path ? null : e)
        .then((path) => path != null ? onChange(path) : null);
  }

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: decoration ?? const InputDecoration(),
        child: InkWell(
          onTap: () => _showFilesystemDialog(context),
          child: Text(path),
        ),
      );
}

class _TextField extends StatefulWidget {
  const _TextField({
    Key? key,
    required this.value,
    this.onChange,
    this.onSubmit,
    this.decoration,
    this.autofocus = false,
  }) : super(key: key);
  final String value;
  final ValueChanged<String>? onChange;
  final ValueChanged<String>? onSubmit;
  final InputDecoration? decoration;
  final bool autofocus;

  @override
  __TextFieldState createState() => __TextFieldState();
}

class __TextFieldState extends State<_TextField> {
  late final TextEditingController controller;
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && controller.text != widget.value) {
      controller.text = widget.value;
    }
  }

  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onChange(String s) {
    if (s == widget.value) {
      return;
    }
    widget.onChange?.call(s);
  }

  void _onSubmit(String s) {
    if (s == widget.value) {
      return;
    }
    widget.onSubmit?.call(s);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: widget.autofocus,
      onChanged: _onChange,
      onSubmitted: _onSubmit,
      decoration: widget.decoration,
    );
  }
}

class _FileWidget extends StatefulWidget {
  const _FileWidget({
    Key? key,
    required this.file,
  }) : super(key: key);
  final ControllerHandle<FileController> file;

  @override
  State<_FileWidget> createState() => _FileWidgetState();
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    Key? key,
    required this.toBeSaved,
    required this.snackbarContent,
    this.icon = const Icon(Icons.copy),
  }) : super(key: key);
  final Widget snackbarContent;
  final ValueListenable<AsyncSnapshot<String>> toBeSaved;
  final Widget icon;

  Widget _button(BuildContext context, String data) => IconButton(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: data)).then((_) =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: snackbarContent)));
        },
        icon: icon,
      );
  @override
  Widget build(BuildContext context) => toBeSaved
      .map(
        (toBeSaved) => toBeSaved.hasData
            ? _button(context, toBeSaved.requireData)
            : CircularProgressIndicator(),
      )
      .build();
}

class _FileWidgetState extends State<_FileWidget> {
  final GlobalKey<AnimatedVectorState> animatedVectorKey = GlobalKey();
  void _save(BuildContext context) {}
  @override
  Widget build(BuildContext context) => FilledCard(
        style: CardStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.file.unwrap.relativeFile
                          .map((rel) => Text(rel.path,
                              style: context.textTheme.titleLarge))
                          .build(),
                      Text(widget.file.unwrap.ref.toString(),
                          style: context.textTheme.titleSmall),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: widget.file.unwrap.onDelete,
                      icon: Icon(Icons.delete_outline),
                    ),
                    _SaveButton(
                      toBeSaved: widget.file.unwrap.formattedGeneratedCode,
                      snackbarContent: Text(
                          'O código para ${widget.file.unwrap.ref} foi copiado!'),
                    ),
                  ],
                )
              ],
            ),
            _HorizontalCenter(
                child: widget.file.unwrap.resolvedVectorSnap
                    .map((snap) => snap.hasData
                        ? AnimatedVectorWidget(
                            key: animatedVectorKey,
                            animatedVector: snap.requireData.body,
                          )
                        : snap.hasError
                            ? Text(snap.error!.toString())
                            : CircularProgressIndicator())
                    .build()),
            _ExpansionAnimation(
              isExpanded: widget.file.unwrap.resolvedVectorSnap
                  .map((snap) => snap.hasData),
              child: _AnimatedVectorControls(
                vectorKey: animatedVectorKey,
              ),
            )
          ],
        ),
      );
}

class _AnimatedVectorControls extends StatelessWidget {
  const _AnimatedVectorControls({
    Key? key,
    required this.vectorKey,
  }) : super(key: key);
  final GlobalKey<AnimatedVectorState> vectorKey;

  void _reset() => vectorKey.currentState!.stop(reset:true);
  void _play() => vectorKey.currentState!.start();
  void _forward() => vectorKey.currentState!.reset();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _reset,
            icon: Icon(Icons.restore),
          ),
          IconButton(
            onPressed: _play,
            icon: Icon(Icons.play_arrow),
          ),
          IconButton(
            onPressed: _forward,
            icon: Icon(Icons.skip_next),
          ),
        ],
      );
}

class _HorizontalCenter extends StatelessWidget {
  const _HorizontalCenter({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [child],
      );
}

class _ExpansionAnimation extends StatelessWidget {
  const _ExpansionAnimation({
    Key? key,
    required this.isExpanded,
    required this.child,
  }) : super(key: key);
  final ValueListenable<bool> isExpanded;
  final Widget child;

  @override
  Widget build(BuildContext context) => isExpanded.buildView(
        builder: (
          context,
          expanded,
          child,
        ) =>
            TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(end: expanded ? 1.0 : 0.0),
          curve: const Interval(2 / 3, 1.0, curve: Curves.easeOut),
          builder: (context, opacity, child) => Opacity(
            opacity: opacity,
            child: child,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: SizedBox(
              width: double.infinity,
              child: Visibility(
                maintainState: true,
                visible: expanded,
                child: child!,
              ),
            ),
          ),
        ),
        child: child,
      );
}

int _compareFileController(FileController a, FileController b) =>
    a.file.path.compareTo(b.file.path);
int _compareNamespaceController(NamespaceController a, NamespaceController b) =>
    a.name.value.compareTo(b.name.value);

class NamespaceController
    extends SubcontrollerBase<ResourceController, NamespaceController> {
  final ValueNotifier<String> _name;
  final ValueNotifier<Directory> _root;
  final ActionNotifier _didDelete = ActionNotifier();

  NamespaceController(String name, Directory root)
      : _name = ValueNotifier(name),
        _root = ValueNotifier(root);

  ValueListenable<String> get name => _name.view();
  ValueListenable<Directory> get root => _root.view();
  ValueListenable<void> get didDelete => _didDelete.view();

  ValueListenable<MapEntry<String, Directory>> get entry =>
      name.bind((name) => root.map((root) => MapEntry(name, root)));

  late final setName = _name.setter;
  late final setRoot = _root.setter;
  late final onDelete = _didDelete.notify;
}

extension AsyncSnapE<T> on AsyncSnapshot<T> {
  AsyncSnapshot<R> map<R>(R Function(T) fn) => hasData
      ? AsyncSnapshot<R>.withData(connectionState, fn(requireData))
      : hasError
          ? AsyncSnapshot<R>.withError(
              connectionState, error!, stackTrace ?? StackTrace.empty)
          : AsyncSnapshot<R>.nothing().inState(connectionState);
  AsyncSnapshot<R> bind<R>(AsyncSnapshot<R> Function(T) fn) => hasData
      ? fn(requireData)
      : hasError
          ? AsyncSnapshot<R>.withError(
              connectionState, error!, stackTrace ?? StackTrace.empty)
          : AsyncSnapshot<R>.nothing().inState(connectionState);
}

class FileController
    extends SubcontrollerBase<ResourceController, FileController> {
  final File file;
  final ValueNotifier<AsyncResourceResolver?> _resolver;
  final ValueNotifier<Directory?> _root;
  final ActionNotifier _didDelete = ActionNotifier();

  FileController(File file, Directory? root, AsyncResourceResolver? resolver)
      : file = file,
        _resolver = ValueNotifier(resolver),
        _root = ValueNotifier(root);

  late final ValueListenable<AsyncSnapshot<AnimatedVectorDrawable>>
      _resolvedVector;
  late final ValueListenable<AsyncSnapshot<AnimatedVectorDrawable>>
      _parsedVectorSnap;

  ValueListenable<AsyncSnapshot<AnimatedVectorDrawable>> get parsedVectorSnap =>
      _parsedVectorSnap.view();
  ValueListenable<AsyncSnapshot<AnimatedVectorDrawable>>
      get resolvedVectorSnap => _resolvedVector.view();
  ValueListenable<AsyncSnapshot<String>> get generatedCode =>
      resolvedVectorSnap.map((e) => e
          .map((drawable) => CodegenAnimatedVectorDrawableVisitor()
              .visitAnimatedVectorDrawable(e.requireData)
              .toString())
          .map((code) => 'final ${ref.name} = $code;'));
  // late final because _formatCode is expensive
  late final ValueListenable<AsyncSnapshot<String>> _formattedGeneratedCode =
      generatedCode.map((code) => code.map(_formatStatement));
  ValueListenable<AsyncSnapshot<String>> get formattedGeneratedCode =>
      _formattedGeneratedCode.view();
  ValueListenable<File> get relativeFile =>
      _root.view().map((root) => File(p.relative(file.path, from: root?.path)));

  ValueListenable<void> get didDelete => _didDelete.view();
  late final setResolver = _resolver.setter;
  late final setRoot = _root.setter;
  late final onDelete = _didDelete.notify;

  void init() {
    super.init();
    file
        .watch(events: FileSystemEvent.delete)
        .toValueListenable()
        .listen(_didDelete.notify);
    _parsedVectorSnap = file
        .watch(events: FileSystemEvent.modify)
        .toValueListenable()
        .tap((_) => print('file modified or gonna be read'))
        .map((_) => file)
        .bind((updatedFile) => updatedFile
            .readAsString()
            .then((_) {
              print('file read');
              return _;
            })
            .then(XmlDocument.parse)
            .then((doc) => AnimatedVectorDrawable.parseDocument(doc, ref))
            .then((_) {
              print('avd parsed');
              return _;
            })
            .toValueListenable()
            .tap((_) => print('avd converted to value listenable')))
        .tap((e) => 'bound avd converted')
        .view();
    _resolvedVector = _resolver
        .tap((e) => print('resolver updated $e'))
        .bind<AsyncSnapshot<AnimatedVectorDrawable>>((resolver) =>
            resolver == null
                ? SingleValueListenable(AsyncSnapshot.waiting())
                : parsedVectorSnap.bind((snap) => snap.hasData
                    ? _resolveVector(snap.requireData, resolver)
                    : SingleValueListenable(snap)))
        .tap((e) => print('avd snapshot: $e'));
  }

  ResourceReference get ref => ResourceReference(
      p.basename(p.dirname(file.path)), p.basenameWithoutExtension(file.path));

  ValueListenable<AsyncSnapshot<AnimatedVectorDrawable>> _resolveVector(
    AnimatedVectorDrawable vector,
    AsyncResourceResolver resolver,
  ) {
    final cloned = vector.clone();
    final unresolved = findAllUnresolvedReferencesInAnimatedVector(cloned.body);
    if (unresolved.isEmpty) {
      return SingleValueListenable(
        AsyncSnapshot.withData(ConnectionState.done, vector),
      );
    }
    return Future.value()
        .then((_) {
          print('gonna resolve');
          return _;
        })
        .then((_) => resolver.resolveMany(unresolved))
        .then((_) {
          print('resolved');
          return _;
        })
        .then((_) => cloned)
        .toValueListenable()
        .tap((_) => print('resolved to value listenable'));
  }
}

class AndroidFilesystemResourceResolver extends AsyncResourceResolver {
  final Map<String, Directory> namespacesMap;

  AndroidFilesystemResourceResolver(this.namespacesMap);
  final Map<ResourceReference, FutureOr<Resource?>> _resourceCache = {};

  R? _parseDocumentAs<R extends Resource>(
      XmlDocument document, ResourceReference source) {
    switch (R) {
      case AnimatedVectorDrawable:
        return AnimatedVectorDrawable.parseDocument(document, source) as R;
      case VectorDrawable:
        return VectorDrawable.parseDocument(document, source) as R;
      case AnimationResource:
        return AnimationResource.parseDocument(document, source) as R;
      case Interpolator:
        return Interpolator.parseDocument(document, source) as R;
      default:
        return null;
    }
  }

  @override
  Future<R?> resolve<R extends Resource>(ResourceReference reference) {
    if (_resourceCache.containsKey(reference)) {
      return Future.value(_resourceCache[reference] as FutureOr<R?>);
    }
    return _resourceCache[reference] = () async {
      final namespaceRoot = namespacesMap[reference.namespace];
      if (namespaceRoot == null) {
        return null;
      }
      final file = File(p.setExtension(
          p.join(namespaceRoot.path, reference.folder, reference.name),
          '.xml'));
      final fileContents = await file.readAsString();
      final document = XmlDocument.parse(fileContents);
      final resource = _parseDocumentAs<R>(document, reference);
      return _resourceCache[reference] = resource;
    }();
  }

  @override
  Future<void> resolveMany(Iterable<ResourceOrReference<Resource>> reference) {
    final unresolved = reference
        .where((element) => element.isResolvable && !element.isResolved);
    return Future.wait(unresolved.map(
      (e) => e.runWithResourceType<Future<void>>(
          <R extends Resource>(self) => resolve<R>(self.reference!).then(
                (resolved) => self.resource = resolved,
              )),
    ));
  }
}

String _formatCode(String code) {
  final formatter = DartFormatter();
  return formatter.format(code);
}

String _formatStatement(String statement) {
  final formatter = DartFormatter();
  return formatter.formatStatement(statement);
}

class ResourceController extends ControllerBase<ResourceController> {
  final ValueNotifier<Directory?> _rootDir;
  final SortedAnimatedListController<FileController> _avdFiles;
  final SortedAnimatedListController<NamespaceController> _namespaces;
  final Set<File> _currentFiles = {};

  ResourceController(
    Directory? root,
    Iterable<File> files,
    Map<String, Directory> namespaces,
  )   : _rootDir = ValueNotifier(root),
        _avdFiles = SortedAnimatedListController.from(
          files.map((f) => FileController.new(f, root, null)),
          _compareFileController,
        ),
        _namespaces = SortedAnimatedListController.from(
          namespaces.entries.map((e) => NamespaceController(e.key, e.value)),
          _compareNamespaceController,
        );
  // Late final because there can be a lot of operations, so taking an view is cheaper
  late final ValueListenable<Map<String, Directory>> _namespacesMap =
      _namespaces.values.bind(
    (vals) => vals.fold<ValueListenable<Map<String, Directory>>>(
      SingleValueListenable({}),
      (prev, e) => prev.bind(
        (prev) => e.entry.map(
          (entry) => Map.fromEntries(prev.entries.followedBy([entry])),
        ),
      ),
    ),
  );
  // Late final because the AndroidFilesystemResourceResolver has side effects.
  late final ValueListenable<AsyncResourceResolver?> _resolver =
      namespacesMap.bind((namespacesMap) => rootDir.map((dir) => dir == null
          ? null
          : AndroidFilesystemResourceResolver({
              '': dir,
              ...namespacesMap,
            })));

  static const kImportStatements = [
    "import 'package:flutter/material.dart' hide ClipPath;",
    "import 'package:vector_drawable/vector_drawable.dart';",
  ];

  // holy snap, i hate this monad stacking that happens without monad
  // transformers.
  late final ValueListenable<AsyncSnapshot<String>> _generatedCode =
      _avdFiles.values.bind(
    (e) => e
        .fold<ValueListenable<AsyncSnapshot<List<String>>>>(
          SingleValueListenable(AsyncSnapshot.withData(
            ConnectionState.done,
            [...kImportStatements],
          )),
          (acc, e) => acc.bind((acc) => e.generatedCode.map(
              (code) => acc.bind((acc) => code.map((code) => [...acc, code])))),
        )
        .map((decls) => decls.map((decls) => decls.join('\n'))),
  );

  // late final because _formatCode is expensive
  late final ValueListenable<AsyncSnapshot<String>> _formattedGeneratedCode =
      generatedCode.map((code) => code.map(_formatCode));

  ValueListenable<Directory?> get rootDir => _rootDir.view();
  ValueListenable<AsyncSnapshot<String>> get generatedCode =>
      _generatedCode.view();
  ValueListenable<AsyncSnapshot<String>> get formattedGeneratedCode =>
      _formattedGeneratedCode.view();

  ValueListenable<AsyncResourceResolver?> get resolver => _resolver.view();
  ValueListenable<Map<String, Directory>> get namespacesMap =>
      _namespacesMap.view();

  ControllerHandle<SortedAnimatedListController<FileController>>
      get avdFilesController => _avdFiles.handle;
  ControllerHandle<SortedAnimatedListController<NamespaceController>>
      get namespacesController => _namespaces.handle;

  late final setRootDir = _rootDir.setter;

  void _deleteFileController(FileController file) {
    removeSubcontroller(file);
    file.dispose();
    _currentFiles.remove(file.file.absolute);
  }

  void _registerFileController(FileController file) {
    file.didDelete.listen(() => _avdFiles.remove(file));
    resolver.connect(file.setResolver);
    rootDir.connect(file.setRoot);
  }

  void _deleteNamespace(NamespaceController namespace) {
    removeSubcontroller(namespace);
    namespace.dispose();
  }

  void _registerNamespace(NamespaceController namespace) {
    namespace.didDelete.listen(() => _namespaces.remove(namespace));
    namespace.name.tap((_) => _namespaces.reSortValue(namespace));
  }

  void addNamespace(String name, Directory root) {
    if (_namespacesMap.value.containsKey(name)) {
      return;
    }
    if (!root.existsSync()) {
      return;
    }
    final controller = ControllerBase.create(
      () => NamespaceController(name, root),
      register: _registerNamespace,
    );
    _namespaces.insert(addSubcontroller(controller));
  }

  void addFile(File file) {
    if (_currentFiles.contains(file.absolute)) {
      return;
    }
    if (!file.existsSync()) {
      return;
    }
    final controller = ControllerBase.create(
      () => FileController(file, _rootDir.value, _resolver.value),
      register: _registerFileController,
    );
    _avdFiles.insert(addSubcontroller(controller));
    _currentFiles.add(file.absolute);
  }

  void addFiles(Iterable<File> file) => file.toSet().forEach(addFile);

  void init() {
    super.init();
    for (final controller in _avdFiles.values.value) {
      addSubcontroller(controller);
    }
    addChild(_avdFiles);
    for (final controller in _namespaces.values.value) {
      addSubcontroller(controller);
    }
    addChild(_namespaces);
    _avdFiles.init();
    _avdFiles.didDiscardItem.tap(_deleteFileController);
    _namespaces.init();
    _namespaces.didDiscardItem.tap(_deleteNamespace);
  }

  void dispose() {
    IDisposable.disposeAll(_avdFiles.values.value);
    IDisposable.disposeAll(_namespaces.values.value);
    IDisposable.disposeAll([
      _rootDir,
      _avdFiles,
      _namespaces,
      _resolver,
    ]);
    super.dispose();
  }
}

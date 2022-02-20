import 'dart:async';
import 'dart:io';

import 'package:code_generator/sorted_animated_list/controller.dart';
import 'package:code_generator/sorted_animated_list/widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_widgets/material_widgets.dart';
import 'package:path/path.dart' as p;
import 'package:value_notifier/value_notifier.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:xml/xml.dart';
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
      factory: (_) => ResourceController(null, []),
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  void _showRootDialog(BuildContext context) {
    final controller =
        InheritedController.get<ResourceController>(context).unwrap;
    picker.FilePicker.platform
        .getDirectoryPath()
        .then((path) => path == null ? null : Directory(path))
        .then((e) => e != null ? controller.setRootDir(e) : null);
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
                : Column(
                    children: [
                      InputDecorator(
                        decoration: const InputDecoration(
                          filled: true,
                          icon: Icon(Icons.folder),
                          labelText: 'Base dos recusos',
                        ),
                        child: InkWell(
                          onTap: () => _showRootDialog(context),
                          child: Text(root.path),
                        ),
                      ),
                      Expanded(
                        child: SortedAnimatedList<FileController>(
                          controller: controller.avdFilesController.unwrap,
                          itemBuilder: (context, file, anim) =>
                              _ListEntranceTransition(
                            animation: anim,
                            child: _FileWidget(file: file.handle),
                          ),
                        ),
                      )
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

class _FileWidget extends StatefulWidget {
  const _FileWidget({
    Key? key,
    required this.file,
  }) : super(key: key);
  final ControllerHandle<FileController> file;

  @override
  State<_FileWidget> createState() => _FileWidgetState();
}

class _FileWidgetState extends State<_FileWidget> {
  final GlobalKey<AnimatedVectorState> animatedVectorKey = GlobalKey();
  @override
  Widget build(BuildContext context) => FilledCard(
        style: CardStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        child: Column(
          children: [
            widget.file.unwrap.relativeFile
                .map((rel) =>
                    Text(rel.path, style: context.textTheme.titleLarge))
                .build(),
            Text(widget.file.unwrap.ref.toString(),
                style: context.textTheme.titleSmall),
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

  void _reset() => vectorKey.currentState!.reset();
  void _play() => vectorKey.currentState!.start();
  void _forward() => vectorKey.currentState!.reset(toFinish: true);

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

class FileController
    extends SubcontrollerBase<ResourceController, FileController> {
  final File file;
  final ValueNotifier<AsyncResourceResolver?> _resolver;
  final ValueNotifier<Directory?> _root;
  final ActionNotifier _wasDeleted = ActionNotifier();

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
  ValueListenable<File> get relativeFile =>
      _root.view().map((root) => File(p.relative(file.path, from: root?.path)));

  ValueListenable<void> get wasDeleted => _wasDeleted.view();
  late final setResolver = _resolver.setter;
  late final setRoot = _root.setter;

  void init() {
    super.init();
    file
        .watch(events: FileSystemEvent.delete)
        .toValueListenable()
        .listen(_wasDeleted.notify);
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
  final Directory root;

  AndroidFilesystemResourceResolver(this.root);
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
      final file = File(p.setExtension(
          p.join(root.path, reference.folder, reference.name), '.xml'));
      final fileContents = await file.readAsString();
      final document = XmlDocument.parse(fileContents);
      final resource = _parseDocumentAs<R>(document, reference);
      return _resourceCache[reference] = resource;
    }();
  }

  @override
  Future<void> resolveMany(Iterable<ResourceOrReference<Resource>> reference) {
    final unresolved = reference
        .where((element) => element.isResolvable && !element.isResolved)
        .toSet();
    return Future.wait(unresolved.map(
      (e) => e.runWithResourceType<Future<void>>(
          <R extends Resource>(self) => resolve<R>(self.reference!).then(
                (resolved) => self.resource = resolved,
              )),
    ));
  }
}

class ResourceController extends ControllerBase<ResourceController> {
  final ValueNotifier<Directory?> _rootDir;
  final SortedAnimatedListController<FileController> _avdFiles;
  final Set<File> _currentFiles = {};

  ResourceController(Directory? root, Iterable<File> files)
      : _rootDir = ValueNotifier(root),
        _avdFiles = SortedAnimatedListController.from(
          files.map((f) => FileController.new(f, root, null)),
          _compareFileController,
        );
  // Late final because the AndroidFilesystemResourceResolver has side effects.
  late final ValueListenable<AsyncResourceResolver?> _resolver = _rootDir.map(
      (dir) => dir == null ? null : AndroidFilesystemResourceResolver(dir));
  ValueListenable<Directory?> get rootDir => _rootDir.view();

  ValueListenable<AsyncResourceResolver?> get resolver => _resolver.view();

  ControllerHandle<SortedAnimatedListController<FileController>>
      get avdFilesController => _avdFiles.handle;

  late final setRootDir = _rootDir.setter;

  void _deleteFileController(FileController file) {
    removeSubcontroller(file);
    file.dispose();
    _currentFiles.remove(file.file.absolute);
  }

  void _registerFileController(FileController file) {
    file.wasDeleted.listen(() => _avdFiles.removeChild(file));
    resolver.connect(file.setResolver);
    rootDir.connect(file.setRoot);
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
    _avdFiles.init();
    _avdFiles.didDiscardItem.tap(_deleteFileController);
  }

  void dispose() {
    IDisposable.disposeAll(_avdFiles.values.value);
    IDisposable.disposeAll([_rootDir, _avdFiles, _resolver]);
    super.dispose();
  }
}

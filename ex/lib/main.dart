import 'package:ex/card.dart';
import 'package:ex/src/drawable/pitu.dart';
import 'package:flutter/material.dart';
import 'package:vector_drawable/vector_drawable.dart' hide Transform;
import 'package:vector_drawable_from_svg/vector_drawable_from_svg.dart'
    hide Transform;

void main() {
  initializeVectorDrawableFlutter();
  runApp(const MyApp());
}

class PituSvg extends StatelessWidget {
  const PituSvg({
    super.key,
    required this.yinYangAnimation,
    required this.childAnimation,
    required this.debugFeatures,
    required this.useDebug,
    this.child,
  });
  final double yinYangAnimation;
  final double childAnimation;
  final Set<Feature> debugFeatures;
  final bool useDebug;
  final Widget? child;

  static final yanTween = Tween(begin: 0.0, end: 100.0);
  static final heartScaleTween = Tween(begin: 1.0, end: 1.5);
  static final yinTween = Tween(begin: 0.0, end: -100.0);
  static final childXTween = Tween(begin: 0.0, end: 100.0);
  static final childYTween = Tween(begin: 0.0, end: 100.0);
  static final childWidthTween = Tween(begin: 100.0, end: 0.0);
  static final childHeightTween = Tween(begin: 100.0, end: 0.0);

  @override
  Widget build(BuildContext context) {
    final vec = useDebug ? debugVectorWithFeatures(debugFeatures) : pituVector;
    final animationStyleResolver = StyleMapping.fromMap(
      {
        'yan:x': yanTween.transform(yinYangAnimation),
        'yin:x': yinTween.transform(yinYangAnimation),
        'child:x': childXTween.transform(childAnimation),
        'child:y': childYTween.transform(childAnimation),
        'child:width': childWidthTween.transform(childAnimation),
        'child:height': childHeightTween.transform(childAnimation),
        'heart:scale': heartScaleTween.transform(childAnimation),
        'heart:strokeOpacity': 1.0,
        'heart:fillOpacity': 1.0,
        'liam:shyCheeksOpacity': 1.0,
      },
      namespace: 'animation',
    );
    final scale = 3.0;
    final radius = 8.0;
    final verticalPadding = 12.0;
    final horizontalPadding = 8.0;
    final materialColor = Theme.of(context).colorScheme.tertiaryContainer;
    final textColor = Theme.of(context).colorScheme.onTertiaryContainer;
    var textStyle = Theme.of(context).textTheme.displayMedium!;
    textStyle = textStyle.copyWith(color: textColor);
    const black = VectorColor.rgba(0x000000ff);
    const stroke = VectorColor.rgba(0x000000ff);
    const red = VectorColor(0xffff0000);
    final clown = false;
    final kStroke = VectorColor.rgba(0x000000ff);
    final pStroke = VectorColor.argb(Colors.grey[850]!.value);
    final liamEarDetail = pStroke;
    final liamShyCheeks = VectorColor.argb(Colors.pink[300]!.value);
    final liamStroke = pStroke;
    final liamWhiskers = VectorColor.argb(Colors.grey[500]!.value);
    final liamWhiskersWidth = 0.132292 / 4;
    final liamNose = clown ? red : pStroke;
    final liamEyes = VectorColor.argb(Colors.brown[700]!.value);
    final liamFill = VectorColor.argb(Colors.grey[900]!.value);
    final kalilStroke = kStroke;
    final kalilEyes = kStroke;
    final kalilNose = clown ? red : kStroke;
    final kalilWhiskers = kStroke;
    final kalilBodyFill = VectorColor.rgba(0xe69843ff);
    final kalilTailFill = VectorColor.rgba(0xd37432ff);
    final heartStroke =
        VectorColor.argb(Color.fromARGB(255, 196, 44, 52).value);
    final heartFill = VectorColor.argb(Color.fromARGB(255, 245, 86, 94).value);
    final liamRed = VectorColor.argb(Color.fromARGB(255, 197, 20, 20).value);
    final kalilPurple =
        VectorColor.argb(Color.fromARGB(255, 115, 69, 194).value);
    final colorsResolver = StyleResolver.fromMap(
      {
        'liam:earDetail': liamEarDetail,
        'liam:shyCheeks': liamShyCheeks,
        'liam:stroke': liamStroke,
        'liam:whiskers': liamWhiskers,
        'liam:whiskersWidth': liamWhiskersWidth,
        'liam:nose': liamNose,
        'liam:eyes': liamEyes,
        'liam:fill': liamFill,
        'kalil:stroke': kalilStroke,
        'kalil:eyes': kalilEyes,
        'kalil:nose': kalilNose,
        'kalil:whiskers': kalilWhiskers,
        'kalil:bodyFill': kalilBodyFill,
        'kalil:tailFill': kalilTailFill,
        'heart:stroke': heartStroke,
        'heart:fill': heartFill,
        'liam:red': liamRed,
        'kalil:purple': kalilPurple,
      },
      namespace: 'color',
    );
    final styleResolver = colorsResolver.mergeWith(animationStyleResolver);
    return Transform.scale(
      scale: scale,
      child: Material(
        shape: CardShape(),
        elevation: 8.0,
        clipBehavior: Clip.antiAlias,
        child: RawVectorWidget(
          vector: pituVectorForAnimation,
          viewportClip: Clip.none,
          styleResolver: styleResolver,
          child: Visibility(
            visible: false,
            child: Transform.scale(
              scale: 1.0,
              child: Center(
                child: Material(
                  color: materialColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius / scale),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: horizontalPadding,
                    ),
                    child: Text(
                      'Eu te amo',
                      style: textStyle.apply(fontSizeFactor: 1 / scale),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: "me mama",
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static final Animatable<double> yinYangTween =
      CurveTween(curve: Curves.linear);
  static final Animatable<double> childTween = CurveTween(curve: Curves.linear);
  late final Animation yinYangAnimation;
  late final Animation childAnimation;
  final Set<Feature> features = {};
  bool useAffine = true;
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    yinYangAnimation = yinYangTween.animate(_controller);
    childAnimation = childTween.animate(_controller);
    _controller..repeat();
  }

  void _toggleAffine() => setState(() => useAffine = !useAffine);
  void _toggleViewportResize() =>
      setState(() => features.contains(Feature.viewportSized)
          ? features.remove(Feature.viewportSized)
          : features.add(Feature.viewportSized));
  void _toggleInlineTransforms() =>
      setState(() => features.contains(Feature.inlinedTransforms)
          ? features.remove(Feature.inlinedTransforms)
          : features.add(Feature.inlinedTransforms));

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: yinYangAnimation,
          builder: (context, child) => AnimatedBuilder(
            animation: childAnimation,
            child: child,
            builder: (context, child) => PituSvg(
              yinYangAnimation: yinYangAnimation.value,
              childAnimation: childAnimation.value,
              useDebug: useAffine,
              debugFeatures: features,
              child: child,
            ),
          ),
          child: Placeholder(
            strokeWidth: 1,
            color: Colors.red,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                onPressed: _toggleViewportResize,
                child: Icon(Icons.border_all),
              ),
              FloatingActionButton.small(
                onPressed: _toggleInlineTransforms,
                child: Icon(Icons.group),
              )
            ],
          ),
          FloatingActionButton.extended(
            onPressed: _toggleAffine,
            label: Text('toggle debug'),
          ),
          Text(
              'features: ${features.map((f) => f.name).join(',')}, debug: $useAffine')
        ],
      ),
    );
  }
}

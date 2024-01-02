import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:xml/xml.dart';
import 'package:vector_drawable/src/visiting/codegen.dart';
import 'package:vector_drawable/src/visiting/async_resolver.dart';
import 'generated_resources.dart' as drawable;
import 'part.dart' as drawable;

void main() {
  runApp(_MyApp());
}

class _MyApp extends StatelessWidget {
  const _MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData.dark(),
        home: Material(
            color: Colors.black,
            child: Center(
              child: _TestVectorWidget(),
            )),
      );
}

class _TestVectorWidget extends StatefulWidget {
  const _TestVectorWidget({Key? key}) : super(key: key);

  @override
  State<_TestVectorWidget> createState() => TestVectorWidgetState();
}

class TestVectorWidgetState extends State<_TestVectorWidget> {
  final animatedVectorKey = GlobalKey<AnimatedVectorState>();
  int _drawableIndex = 6;
  bool _animated = true;
  void _reset() => animatedVectorKey.currentState!.reset();
  void _start() => animatedVectorKey.currentState!.start();
  void _stop() => animatedVectorKey.currentState!.stop();
  void _next() => setState(() => _drawableIndex++);
  void _toggleAnimated() => setState(() => _animated = !_animated);

  @override
  Widget build(BuildContext context) {
    final drawables = [
      drawable.avd_tab_alarm_white_24dp.body,
      drawable.avd_tab_bedtime_white_24dp.body,
      drawable.avd_tab_clock_white_24dp.body,
      drawable.avd_tab_stopwatch_white_24dp.body,
      drawable.avd_tab_timer_white_24dp.body,
      drawable.avd_bedtime_onboarding_graphic.body,
      drawable.avd_bedtime_onboarding_graphic_colored_background.body,
      drawable.drawable.body,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Vector sample'),
      ),
      body: Stack(
        children: [
          Center(
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Transform.scale(
                  scale: 1,
                  child: _animated
                      ? AnimatedVectorWidget(
                          key: animatedVectorKey,
                          animatedVector:
                              drawables[_drawableIndex % drawables.length],
                        )
                      : VectorWidget(
                          vector: drawables[_drawableIndex % drawables.length]
                              .drawable
                              .resource!
                              .body,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: Wrap(
              spacing: 4.0,
              runSpacing: 4.0,
              verticalDirection: VerticalDirection.up,
              children: [
                TextButton(
                  onPressed: _animated ? _start : null,
                  child: Text('start'),
                ),
                TextButton(
                  onPressed: _animated ? _stop : null,
                  child: Text('stop'),
                ),
                TextButton(
                  onPressed: _animated ? _reset : null,
                  child: Text('reset'),
                ),
                TextButton(
                  onPressed: _next,
                  child: Text('next'),
                ),
                TextButton(
                  onPressed: _toggleAnimated,
                  child: Text('toggle animated'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vector_drawable/vector_drawable.dart';
import 'package:xml/xml.dart';
import 'package:vector_drawable/src/visiting/codegen.dart';

void main() {
  print('done');
  print('fubá');
  runApp(_MyApp());
}

class _MyApp extends StatelessWidget {
  const _MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
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
  State<_TestVectorWidget> createState() => _TestVectorWidgetState();
}

class _TestVectorWidgetState extends State<_TestVectorWidget> {
  final animatedVectorKey = GlobalKey<AnimatedVectorState>();
  @override
  Widget build(BuildContext context) {
    final kTextXml = '''
<animated-vector
  xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt">
    <aapt:attr name="android:drawable">
      <vector android:height="24.0dip" android:width="24.0dip" android:viewportWidth="240.0" android:viewportHeight="240.0"
        xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt">
          <group android:scaleX="9.91" android:scaleY="9.91" android:translateX="120.0" android:translateY="120.0">
              <path android:fillColor="#ffffffff" android:pathData="M -0.0050048828125,-10.0 c -5.52699279785,0.0 -9.99499511719,4.47700500488 -9.99499511719,10.0 c 0.0,5.52299499512 4.46800231934,10.0 9.99499511719,10.0 c 5.52600097656,0.0 10.0050048828,-4.47700500488 10.0050048828,-10.0 c 0.0,-5.52299499512 -4.47900390625,-10.0 -10.0050048828,-10.0 Z M 0.0,8.0 c -4.41999816895,0.0 -8.0,-3.58200073242 -8.0,-8.0 c 0.0,-4.41799926758 3.58000183105,-8.0 8.0,-8.0 c 4.41999816895,0.0 8.0,3.58200073242 8.0,8.0 c 0.0,4.41799926758 -3.58000183105,8.0 -8.0,8.0 Z" />
          </group>
          <group android:name="clock_hour_hand" android:scaleX="0.91922" android:scaleY="3.67245" android:translateX="117.75" android:translateY="128.25">
              <path android:fillColor="#ffffffff" android:pathData="M -8.236815,-15.804225 l 15.97363,0.0 c 0.0,0.0 0.0,0.0 0.0,0.0 l 0.0,15.97363 c 0.0,0.0 0.0,0.0 0.0,0.0 l -15.97363,0.0 c 0.0,0.0 0.0,0.0 0.0,0.0 l 0.0,-15.97363 c 0.0,0.0 0.0,0.0 0.0,0.0 Z" />
          </group>
          <group android:name="clock_minute_hand" android:scaleX="0.91922" android:scaleY="3.67245" android:rotation="121.0" android:translateX="114.25" android:translateY="124.0">
              <path android:fillColor="#ffffffff" android:pathData="M -8.236815,-15.804225 l 15.97363,0.0 c 0.0,0.0 0.0,0.0 0.0,0.0 l 0.0,15.97363 c 0.0,0.0 0.0,0.0 0.0,0.0 l -15.97363,0.0 c 0.0,0.0 0.0,0.0 0.0,0.0 l 0.0,-15.97363 c 0.0,0.0 0.0,0.0 0.0,0.0 Z" />
          </group>
      </vector>
    </aapt:attr>

    <target android:name="clock_hour_hand" >
      <aapt:attr name="android:animation">
        <set
          xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt">
            <set android:ordering="sequentially">
                <set android:ordering="together">
                  <objectAnimator android:duration="166" android:valueFrom="117.75" android:valueTo="116.68351" android:propertyName="translateX" />
                  <objectAnimator android:duration="166" android:valueFrom="128.25" android:valueTo="128.05357" android:propertyName="translateY" />
                </set>
                <set android:ordering="together">
                  <objectAnimator android:duration="417" android:valueFrom="116.68351" android:valueTo="114.26022" android:propertyName="translateX" />
                  <objectAnimator android:duration="417" android:valueFrom="128.05357" android:valueTo="124.41091" android:propertyName="translateY" />
                </set>
                <set android:ordering="together">
                  <objectAnimator android:duration="250" android:valueFrom="114.26022" android:valueTo="114.25" android:propertyName="translateX" />
                  <objectAnimator android:duration="250" android:valueFrom="124.41091" android:valueTo="124.0" android:propertyName="translateY" />
                </set>
            </set>
            <objectAnimator android:duration="833" android:valueFrom="0.0" android:valueTo="121.0" android:valueType="floatType" android:propertyName="rotation" />
        </set>
      </aapt:attr>
    </target>
    <target android:name="clock_minute_hand">
      <aapt:attr name="android:animation">
        <set
          xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt">
            <set android:ordering="sequentially">
                <set android:ordering="together">
                  <objectAnimator android:duration="166" android:valueFrom="114.25" android:valueTo="115.55177" android:propertyName="translateX" />
                  <objectAnimator android:duration="166" android:valueFrom="124.0" android:valueTo="124.26329" android:propertyName="translateY" />
                </set>
                <set android:ordering="together">
                  <objectAnimator android:duration="417" android:valueFrom="115.55177" android:valueTo="117.74111" android:propertyName="translateX" />
                  <objectAnimator android:duration="417" android:valueFrom="124.26329" android:valueTo="127.62279" android:propertyName="translateY" />
                </set>
                <set android:ordering="together">
                  <objectAnimator android:duration="250" android:valueFrom="114.26022" android:valueTo="117.75" android:propertyName="translateX" />
                  <objectAnimator android:duration="250" android:valueFrom="127.62279" android:valueTo="128.25" android:propertyName="translateY" />
                </set>
            </set>
            <objectAnimator android:duration="833" android:valueFrom="121.0" android:valueTo="360.0" android:valueType="floatType" android:propertyName="rotation" />
        </set>
      </aapt:attr>
    </target>
</animated-vector>
''';
    final doc = XmlDocument.parse(kTextXml);
    final testVector = AnimatedVectorDrawable.parseDocument(
      doc,
      ResourceReference('drawable', 'avd_example'),
    );
    print(CodegenAnimatedVectorDrawableVisitor()
        .visitAnimatedVectorDrawable(testVector)
        .toString());
    void _reset() => animatedVectorKey.currentState!.reset();
    void _start() => animatedVectorKey.currentState!.start();
    void _stop() => animatedVectorKey.currentState!.stop();
    final vec = testVector.body.drawable.resource!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Vector sample'),
      ),
      body: Stack(
        children: [
          Center(
            child: Material(
              child: Padding(
                padding: const EdgeInsets.all(120.0),
                child: VectorWidget(
                  vector: vec.body,
                ),
              ),
            ),
          ),
          Center(
            child: Material(
              color: Theme.of(context).colorScheme.inverseSurface,
              child: Padding(
                padding: const EdgeInsets.all(120.0),
                child: Transform.scale(
                  scale: 10,
                  child: AnimatedVectorWidget(
                    key: animatedVectorKey,
                    animatedVector: testVector.body,
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
                  onPressed: _start,
                  child: Text('start'),
                ),
                TextButton(
                  onPressed: _stop,
                  child: Text('stop'),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text('reset'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

final avd = AnimatedVectorDrawable(
    AnimatedVector(
      ResourceOrReference.resource(VectorDrawable(
          Vector(
            name: null,
            width: Dimension(64.0, DimensionKind.dp),
            height: Dimension(64.0, DimensionKind.dp),
            viewportWidth: 600.0,
            viewportHeight: 600.0,
            tint: null,
            children: [
              Group(
                name: 'rotationGroup',
                rotation: 45.0,
                pivotX: 300.0,
                pivotY: 300.0,
                scaleX: null,
                scaleY: null,
                translateX: null,
                translateY: null,
                children: [
                  Path(
                    name: 'v',
                    pathData: PathData.fromString(
                        'M300,70 l 0,-70 70,70 0,0 -70,70z'),
                    fillColor: ColorOrStyleColor.color(Color(0xff000000)),
                    strokeColor: null,
                  ),
                ],
              ),
            ],
          ),
          null)),
      [
        Target(
            'rotationGroup',
            ResourceOrReference.resource(AnimationResource(
                ObjectAnimation(
                  propertyName: 'rotation',
                  duration: 6000,
                  valueFrom: 0.0,
                  valueTo: 360.0,
                  startOffset: 6000,
                  repeatCount: 6000,
                ),
                null))),
        Target(
            'v',
            ResourceOrReference.resource(AnimationResource(
                AnimationSet(
                  AnimationOrdering.together,
                  [
                    ObjectAnimation(
                      propertyName: 'pathData',
                      duration: 3000,
                      valueFrom: PathData.fromString(
                          'M300,70 l 0,-70 70,70 0,0 -70,70z'),
                      valueTo: PathData.fromString(
                          'M300,70 l 0,-70 70,0  0,140 -70,0 z'),
                      startOffset: 3000,
                      repeatCount: 3000,
                    ),
                  ],
                ),
                null))),
      ],
    ),
    ResourceReference('drawable', 'avd_example'));

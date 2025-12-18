import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/fsg.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class AnimatedCheckerBoardScene extends Scene {
  AnimatedCheckerBoardScene() :
        exampleVbo = VertexBuffer.v3t2();

  final VertexBuffer exampleVbo;
  final Size quadExtents = Size(500, 500);

  Color color1 = Colors.blue;
  Color color2 = Colors.yellow;
  double patternScale = 5;

  @override
  void init(BuildContext context, RenderingContext gl) {
    super.init(context, gl);
    exampleVbo.init(gl);

    exampleVbo.makeTexturedUnitQuad(
      Rect.fromLTWH(-quadExtents.width/2, -quadExtents.height/2, quadExtents.width, quadExtents.height),
      0.1,
    );
  }

  @override
  void dispose() {}

  void drawVBO(Matrix4 pMatrix, Matrix4 mvMatrix) {
    var shader = FSG().shaders.checkerBoard;
    gl.useProgram(shader.program);
    ShaderList.setMatrixUniforms(shader, pMatrix, mvMatrix);
    gl.enable(WebGL.DEPTH_TEST);


    shader.setPatternColor1(color1);
    shader.setPatternColor2(color2);
    shader.setPatternScale(patternScale);

    exampleVbo.drawSetup();
    exampleVbo.drawTriangles();
    exampleVbo.drawTeardown();
  }

  void createViewMatrix() {
    Vector3 up = Vector3(0, 1, 0);
    Vector3 orbitCenter = Vector3(0,0,0);
    Vector3 eyeLocation = Vector3(0,0,-500);

    mvMatrix = createLookAtMatrix(eyeLocation, orbitCenter, up);
    mvMatrix.translateByVector3(orbitCenter);
    mvMatrix.rotateZ(radians(180));
    mvMatrix.rotateY(radians(0));
    mvMatrix.rotateX(radians(45));
    mvMatrix.translateByVector3(-orbitCenter);
  }

  void createProjectionMatrix() {
    final double aspectRatio = viewportSize.width / viewportSize.height;

    setPerspectiveMatrix(
      pMatrix,
      radians(60),
      aspectRatio,
      0.1,
      5000000,
    );
  }

  Color getCyclingColor({
    required double timeInSeconds,
    double cycleDurationSeconds =
    10.0, // Default to 10 seconds for a full cycle
    double saturation = 1.0,
    double value = 1.0,
  }) {
    // Normalize time to a value between 0.0 and 1.0 based on cycleDuration
    final double normalizedTime =
        (timeInSeconds % cycleDurationSeconds) / cycleDurationSeconds;

    // Map the normalized time to a hue angle (0.0 to 360.0 degrees)
    final double hue = normalizedTime * 360.0;

    // Create an HSVColor and convert it to a standard Color object
    final HSVColor hsvColor = HSVColor.fromAHSV(1.0, hue, saturation, value);
    return hsvColor.toColor();
  }

  @override
  void drawScene() {
    gl.clearColor(1.0, 1.0, 1.0, 1.0);

    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    gl.enable(WebGL.DEPTH_TEST);
    gl.enable(WebGL.BLEND);
    gl.disable(WebGL.CULL_FACE);
    gl.depthFunc(WebGL.LESS);

    createProjectionMatrix();
    createViewMatrix();
    double cycleDuration = 2;

    DateTime now = DateTime.now();
    double timeInSeconds = now.millisecondsSinceEpoch / 1000.0;
    Color cycleColor = getCyclingColor(
      timeInSeconds: timeInSeconds,
      cycleDurationSeconds: cycleDuration,
    );
    color1 = cycleColor;

    Color cycleColor2 = getCyclingColor(
      timeInSeconds: timeInSeconds + 1,
      cycleDurationSeconds: cycleDuration,
    );
    color2 = cycleColor2;

    // TODO: Animate the scale from 1 - 100

    mvPushMatrix();
    drawVBO(pMatrix, mvMatrix);

    mvPopMatrix();

    gl.finish();
  }
}

class AnimatedCheckerBoardExample extends StatefulWidget {
  const AnimatedCheckerBoardExample({super.key});

  @override
  AnimatedCheckerBoardExampleState createState() => AnimatedCheckerBoardExampleState();
}

class AnimatedCheckerBoardExampleState extends State<AnimatedCheckerBoardExample> {
  late AnimatedCheckerBoardScene scene;

  @override
  void initState() {
    super.initState();
    scene = AnimatedCheckerBoardScene();
    FSG().registerSceneAndAllocateTexture(scene);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RenderToTexture(scene: scene),
      ],
    );
  }

}
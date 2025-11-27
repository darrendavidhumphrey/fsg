import 'package:flutter/cupertino.dart';
import 'package:flutter_angle/desktop/angle.dart';
import 'package:flutter_angle/shared/options.dart';
import '../frame_counter.dart';
import '../logging.dart';
import 'opengl_scene.dart';

class FlutterAngleManager with LoggableClass {
  FlutterAngle angle = FlutterAngle();
  bool isInitialized = false;
  bool glIsInitialized = false;

  static final double renderToTextureSize = 4096;
  final Map<OpenGLScene, FlutterAngleTexture> scenes = {};

  final textures = <FlutterAngleTexture>[];

  static final FlutterAngleManager _singleton = FlutterAngleManager._internal();

  late FrameCounterModel frameCounter;

  factory FlutterAngleManager() {
    return _singleton;
  }

  FlutterAngleManager._internal();

  Future<bool> init() async {
    if (!isInitialized) {
      isInitialized = true;
      await angle.init();
      glIsInitialized = true;

      return true;
    }
    return false;
  }

  Future<FlutterAngleTexture?> allocTexture(AngleOptions options) async {
    if (glIsInitialized) {

      var newTexture = await angle.createTexture(options);
      textures.add(newTexture);
      return newTexture;
    }
    return null;
  }

  void initScene(BuildContext context, OpenGLScene scene) {
    if (!scene.isInitialized) {
      scene.init(context, scene.renderToTextureId!.getContext());
    }
  }
  void initPlatformState(BuildContext context, OpenGLScene scene) {
   frameCounter = FrameCounterModel();
   init();
  }

  Future<bool> allocTextureForScene(OpenGLScene scene) async {
    final options = AngleOptions(
      width: scene.textureWidth(),
      height: scene.textureHeight(),
      dpr: 1,
      antialias: true,
      useSurfaceProducer: true,
    );

    // Allocate an open GL texture for each scene
    var textureId = await allocTexture(options);

    bool success = (textureId != null);
    if (success) {
      scene.renderToTextureId = textureId;
      scenes[scene] = textureId;
    }
    return success;
  }
}

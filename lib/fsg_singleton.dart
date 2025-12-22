import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/shaders/shaders.dart';
import 'package:fsg/shaders/materials.dart';
import 'package:fsg/texture_manager.dart';
import 'frame_counter.dart';
import 'logging.dart';
import 'bitmap_fonts/bitmap_font_manager.dart';
import 'scene.dart';

class FSG with LoggableClass {
  FlutterAngle angle = FlutterAngle();
  bool isInitialized = false;
  bool glIsInitialized = false;
  bool contextInitialized = false;

  static double renderToTextureSize = 4096;
  final Map<Scene, FlutterAngleTexture> scenes = {};
  final shaders = ShaderList();
  final textures = <FlutterAngleTexture>[];
  final materials = MaterialList();
  final fonts = BitmapFontList();

  static final FSG _singleton = FSG._internal();

  late FrameCounterModel frameCounter;

  factory FSG() {
    return _singleton;
  }

  FSG._internal();

  Future<bool> init() async {
    if (!isInitialized) {
      isInitialized = true;
      await angle.init();
      glIsInitialized = true;

      return true;
    }
    return false;
  }

  Future<FlutterAngleTexture?> allocTexture(AngleOptions options,{double textureSize=4096}) async {
    if (glIsInitialized) {
      var newTexture = await angle.createTexture(options);
      textures.add(newTexture);
      return newTexture;
    }
    return null;
  }

  void initScene(BuildContext context, Scene scene) {
    if (!scene.isInitialized) {
      scene.init(scene.renderToTextureId!.getContext());
    }
  }
  void initPlatformState() {
   frameCounter = FrameCounterModel();
   init();
  }

  void initDefaultMaterial() {
    Color defaultGrey = Colors.grey[200]!;
    Color defaultSpecular = Colors.black;
    const double defaultShininess = 5;

    materials.setDefaultMaterial(
      GlMaterial(defaultGrey, defaultGrey, defaultSpecular, defaultShininess),
    );
  }

  void initContext(RenderingContext gl) {
    if (!contextInitialized) {
      TextureManager().init(gl);
      initDefaultMaterial();

      shaders.init(gl);
      BitmapFontList().createDefaultFont();
      contextInitialized = true;
    }
  }

  // Use this method to register your scene with FSG and allocate a texture for the scene
  // FSG scenes are rendered to a texture and then composited into flutter using either
  // the RenderToTexture widget or InteractiveRenderToTextureWidget
  Future<bool> registerSceneAndAllocateTexture(Scene scene) async {
    final options = AngleOptions(
      width: scene.textureWidth,
      height: scene.textureHeight,
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

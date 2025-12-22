import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/shaders/shaders.dart';
import 'package:fsg/shaders/materials.dart';
import 'package:fsg/texture_manager.dart';
import 'frame_counter.dart';
import 'logging.dart';
import 'bitmap_fonts/bitmap_font_manager.dart';
import 'scene.dart';

// Enum to manage the initialization state of the FSG singleton.
enum _FsgState {
  uninitialized,
  glInitialized,
  contextInitialized,
}

class FSG with LoggableClass {
  FlutterAngle angle = FlutterAngle();
  _FsgState _state = _FsgState.uninitialized;

  static double renderToTextureSize = 4096;
  final Map<Scene, FlutterAngleTexture> scenes = {};
  final shaders = ShaderList();
  final renderToTextureList = <FlutterAngleTexture>[];
  final materials = MaterialList();
  final fonts = BitmapFontList();
  final textureManager = TextureManager();

  static final FSG _singleton = FSG._internal();

  late FrameCounterModel frameCounter;

  factory FSG() {
    return _singleton;
  }

  FSG._internal();

  /// Initializes the core FlutterAngle engine.
  /// This must be called once before any other operations.
  Future<bool> init() async {
    if (_state != _FsgState.uninitialized) {
      return false;
    }
    await angle.init();
    _state = _FsgState.glInitialized;
    return true;
  }

  /// Allocates a new FlutterAngleTexture with the given options.
  Future<FlutterAngleTexture?> allocTexture(AngleOptions options,
      {double textureSize = 4096}) async {
    if (_state == _FsgState.uninitialized) {
      logWarning("allocTexture called before FSG is initialized.");
      return null;
    }
    var newTexture = await angle.createTexture(options);
    renderToTextureList.add(newTexture);
    return newTexture;
  }

  /// Initializes a [Scene] with its rendering context.
  void initScene(Scene scene) {
    if (!scene.isInitialized) {
      scene.init(scene.renderToTextureId!.getContext());
    }
  }

  /// Initializes platform-specific state, including the frame counter and the engine.
  void initPlatformState() {
    frameCounter = FrameCounterModel();
    init();
  }

  /// Initializes the default material used for rendering.
  void initDefaultMaterial() {
    Color defaultGrey = Colors.grey[200]!;
    Color defaultSpecular = Colors.black;
    const double defaultShininess = 5;

    materials.setDefaultMaterial(
      GlMaterial(defaultGrey, defaultGrey, defaultSpecular, defaultShininess),
    );
  }

  /// Initializes shared context-specific resources like shaders and textures.
  void initContext(RenderingContext gl) {
    if (_state == _FsgState.contextInitialized) {
      return;
    }
    textureManager.initializeGl(gl);
    initDefaultMaterial();

    shaders.init(gl);
    BitmapFontList().createDefaultFont();
    _state = _FsgState.contextInitialized;
  }

  /// Disposes all scenes, textures, shaders, and other GPU resources.
  Future<void> dispose() async {
    for (var scene in scenes.keys) {
      scene.dispose();
    }

    // TODO: Dispose textures

    scenes.clear();
    renderToTextureList.clear();

    shaders.dispose();
    await textureManager.dispose();

    // After disposing context-specific resources, we revert to the GL-initialized state.
    if (_state == _FsgState.contextInitialized) {
      _state = _FsgState.glInitialized;
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

import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

class GameSceneData {
  final String version;
  final Map<String, TextureData> textures;
  final Map<String, FontData> fonts;
  final Map<String, AnchorData> anchors;
  final List<SceneObject> objects;
  final Map<String, SceneObject> _objectMap = {};

  GameSceneData({
    required this.version,
    required List<TextureData> textures,
    required List<FontData> fonts,
    required List<AnchorData> anchors,
    required this.objects,
  })  : textures = {for (var t in textures) t.id: t},
        fonts = {for (var f in fonts) f.id: f},
        anchors = {for (var a in anchors) a.id: a} {
    for (var obj in objects) {
      _registerObject(obj);
    }
  }

  void _registerObject(SceneObject obj) {
    _objectMap[obj.id] = obj;
    if (obj is GroupData) {
      for (var child in obj.children) {
        _registerObject(child);
      }
    }
  }

  SceneObject? findObject(String id) => _objectMap[id];
}

class TextureData {
  final String id;
  final String file;

  TextureData({required this.id, required this.file});
}

class FontData {
  final String id;
  final String fntFile;
  final String texture;

  FontData({
    required this.id,
    required this.fntFile,
    required this.texture,
  });
}

class AnchorData {
  final String id;
  final Vector3 val;

  AnchorData({required this.id, required this.val});
}

abstract class SceneObject {
  final String id;
  SceneObject({required this.id});
}

class QuadData extends SceneObject {
  final String texture;
  final Rect screenRect;
  final Rect textureRect;
  final bool premultiplyAlpha;

  QuadData({
    required String id,
    required this.texture,
    required this.screenRect,
    required this.textureRect,
    this.premultiplyAlpha = false,
  }) : super(id: id);
}

class GroupData extends SceneObject {
  final Vector3 anchor;
  final List<SceneObject> children;

  GroupData({
    required String id,
    required this.anchor,
    required this.children,
  }) : super(id: id);
}

class TextData extends SceneObject {
  final String font;
  final String text;
  final Rect screenRect;
  final String? hJustify;
  final int? maxLen;
  final bool scaleToFit;

  TextData({
    required String id,
    required this.font,
    required this.text,
    required this.screenRect,
    this.hJustify,
    this.maxLen,
    this.scaleToFit = false,
  }) : super(id: id);
}

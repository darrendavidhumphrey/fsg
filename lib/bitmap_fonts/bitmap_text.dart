import 'dart:ui';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:vector_math/vector_math_64.dart';

import '../float32_array_filler.dart';
import '../reference_box.dart';
import '../vertex_buffer.dart';
import 'bitmap_font.dart';

class BitmapText {
  List<Quad> quads = [];
  List<Rect> textureQuads = [];

  String _text = "";

  final ReferenceBox _screenRect;

  bool _needsRebuild = true;
  bool get needsRebuild => _needsRebuild;

  String get text => _text;

  late BitmapFont _font;
  BitmapFont get font => _font;

  late double _width;

  VertexBuffer? vbo;

  BitmapText(this._font, this._text, this._screenRect) {
    _width = _screenRect.xVector.length;
  }

  void dispose() {
    if (vbo != null) {
      vbo!.dispose();
    }
  }

  // For debugging
  void setNeedsRebuild() {
    _needsRebuild = true;
  }

  void setFont(BitmapFont font) {
    _font = font;
    _needsRebuild = true;
  }

  void setText(String text) {
    _text = text;
    _needsRebuild = true;
  }

  double kerningForPair(int first, int second) {
    return _font.kerningForPair(first, second);
  }

  double widthOfString(String str) {
    return _font.widthOfString(str);
  }

  void rebuild(RenderingContext gl, DateTime now) {
    rebuildQuads();

    vbo ??= VertexBuffer.v3t2(gl);

    int vertexCount = _text.length * 6; // Two triangles per character quad

    Float32Array? vertexTexCoordArray = vbo!.requestBuffer(vertexCount);

    if (vertexTexCoordArray != null) {
      Float32ArrayFiller filler = Float32ArrayFiller(vertexTexCoordArray);

      for (int i = 0; i < quads.length; i++) {
        Quad rect = quads[i];
        Rect textureRect = textureQuads[i];

        filler.addTexturedQuad(rect, textureRect);
      }
    }

    vbo!.setActiveVertexCount(vertexCount);
  }

  void rebuildQuads() {
    quads.clear();
    textureQuads.clear();

    double lineLength = widthOfString(text);
    double ratio = _width / lineLength;
    double currentX = 0;
    double lineHeight = _font.lineHeight * ratio;
    double vCenter = -lineHeight / 2;

    double textureScaleW = _font.scaleW;
    double textureScaleH = _font.scaleH;

    for (int i = 0; i < _text.length; i++) {
      CharInfo? charInfo = _font.chars[_text[i]];

      if (charInfo != null) {
        double kerning = 0.0;

        // If not the last character, look up kerning info for this character and the next
        if ((i + 1) < _text.length) {
          kerning = kerningForPair(
            _text.codeUnitAt(i),
            _text.codeUnitAt(i + 1),
          );
        }

        Vector2 blc = Vector2(
          currentX + charInfo.xOffset * ratio,
          charInfo.region.height * ratio + vCenter,
        );
        Vector2 trc = Vector2(
          currentX + charInfo.xOffset * ratio + charInfo.region.width * ratio,
          vCenter,
        );

        Quad charRect = _screenRect.calcQuadFrom2DVectors(blc, trc);

        quads.add(charRect);

        double tLeft = charInfo.region.left / textureScaleW;
        double tTop =
            1 -
                (textureScaleH - (charInfo.region.top + charInfo.region.height)) /
                    textureScaleH;

        Rect textureQuad;
        if (_text[i] == ' ') {
          textureQuad = Rect.zero;
        } else {
          textureQuad = Rect.fromLTRB(
            tLeft,
            tTop,
            tLeft + charInfo.region.width / textureScaleW,
            tTop - charInfo.region.height / textureScaleH,
          );
        }
        textureQuads.add(textureQuad);

        currentX += (charInfo.xAdvance + kerning) * ratio;
      }
    }

    _needsRebuild = false;
  }
}

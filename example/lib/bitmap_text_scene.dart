import 'package:flutter_angle/flutter_angle.dart';
import 'package:fsg/fsg.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class BitmapTextScene extends Scene {
  BitmapTextScene();

  List<BitmapText> textItems = [];

  @override
  void dispose() {}

  @override
  void init(RenderingContext gl) {
    super.init(gl);

    loadCustomFonts();
  }

  void loadCustomFonts()  {
    BitmapFontManager().createFontFromFile(
      "Arial36",
      "assets/Arial36.fnt",
      "Arial36.png",
    );

    BitmapFontManager().createFontFromFile(
      "Scoreboard140",
      "assets/Scoreboard140.fnt",
      "Scoreboard140.png",
    );
  }

  void createTextItems() {
    // Can't create text items until the default font is created
  if (BitmapFontManager().defaultFont == null) return;

  BitmapFont defaultFont = BitmapFontManager().defaultFont!;

    textItems.add(
      BitmapText.origin(text: "HELLO WORLD", font:defaultFont,origin: Vector3(0, 0, 0),scale: 0.25),
    );

    BitmapFont arial36 = BitmapFontManager().getFont("Arial36")!;
    textItems.add(
      BitmapText.origin(text: "Arial Text", font:arial36,origin: Vector3(0, 100, 0),scale: 0.25),
    );

  BitmapFont scoreboard = BitmapFontManager().getFont("Scoreboard140")!;

  textItems.add(
    BitmapText.origin(text: "0123456789", font:scoreboard,origin: Vector3(0, 75, 0),scale: 0.25),
  );
  }

  void updateTextItems() {
    if (textItems.isEmpty) {
      createTextItems();
    }
    for (BitmapText child in textItems) {
      if (child.needsRebuild) {
        child.rebuild(gl);
      }
    }
  }

  @override
  void drawScene() {
    super.drawScene();

    updateTextItems();

    if  (textItems.isEmpty)  return;

    gl.viewport(
      0,
      0,
      FSG.renderToTextureSize.toInt(),
      FSG.renderToTextureSize.toInt(),
    );
    gl.enable(WebGL.BLEND);
    gl.disable(WebGL.CULL_FACE);
    gl.disable(WebGL.DEPTH_TEST);
    gl.clearColor(0.0, 1.0, 1.0, 1.0);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    withPushedMatrix(() {

      BitmapText.drawSetup(gl, pMatrix, mvMatrix);

      for (var text in textItems) {
        if (text.font!.fontTexture != null) {
          gl.bindTexture(WebGL.TEXTURE_2D, text.font!.fontTexture);

          text.vbo.bind();
          text.vbo.drawTriangles();
          text.vbo.unbind();
        }
      }
      gl.bindTexture(WebGL.TEXTURE_2D, null);

    });

    requestRepaint();
  }
}

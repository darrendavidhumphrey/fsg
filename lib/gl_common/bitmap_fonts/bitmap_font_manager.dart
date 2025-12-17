
import 'bitmap_font.dart';
part 'built_in_font.dart';

class BitmapFontList {
  final Map<String,BitmapFont> fonts={};

  void registerFont(String name,BitmapFont font) {
    fonts[name]=font;
  }

  BitmapFont? getFont(String name) {
    return fonts[name];
  }
  void createFont(String fontName,String xmlString, String textureName) {
    if (!fonts.containsKey(fontName)) {
      var font = BitmapFont.loadFromXML(fontName,xmlString);
      font.loadTexture(textureName);
      registerFont(fontName, font);
    }
  }

  void createDefaultFont() {
    createFont("default",creatoDisplayBoldXml,"CreatoDisplay-Bold.png");
  }

  BitmapFont get defaultFont {
    return fonts["default"]!;
  }

}
import 'bitmap_font.dart';
part 'built_in_font.dart';


/// A manager for loading, creating, and accessing [BitmapFont] objects.
///
/// This class is intended to be held by a central singleton (e.g., FSG) and is
/// responsible for caching fonts and ensuring their textures are loaded before use.
class BitmapFontManager {
  /// The internal cache of registered fonts, keyed by their unique name.
  final Map<String, BitmapFont> _fonts = {};

  // A list of the fonts current in process of loading
  final Map<String,bool>_fontsInProgress={};

  /// The singleton instance.
  static final BitmapFontManager _singleton = BitmapFontManager._internal();

  /// Factory constructor to return the singleton instance.
  factory BitmapFontManager() {
    return _singleton;
  }

  /// Internal constructor for the singleton.
  BitmapFontManager._internal();

  /// Registers a pre-loaded [BitmapFont] instance with a given [name].
  void registerFont(String name, BitmapFont font) {
    _fonts[name] = font;
  }

  /// Retrieves a font by its registered [name].
  ///
  /// Returns `null` if a font with the given name has not been registered.
  BitmapFont? getFont(String name) {
    return _fonts[name];
  }

  /// Returns the default font, which is expected to be named "default".
  /// Lazily creates the font if it doesn't exist.
  BitmapFont? get defaultFont {
    final font = _fonts["default"];

    // Asynchronously Lazily instantiate the default font
    if (font == null) {
      createDefaultFont();
    }
    return font;
  }

  /// Creates a font from XML data, loads its texture, and registers it.
  ///
  /// This method is asynchronous to ensure the font's texture is fully loaded
  /// from assets and ready for rendering before the font is registered. This
  /// prevents race conditions where a font might be used before its texture is valid.
  Future<void> createFont(
      String fontName, String xmlString, String textureName) async {

    // Don't create font if loading is in progress or it's already created
    if (_fontsInProgress.containsKey(fontName) || _fonts.containsKey(fontName)) {
      return;
    }

    // Mark font name as in progress
    _fontsInProgress[fontName] = true;

    var font = BitmapFont.fromXml(fontName, xmlString);

    // Await the texture loading before registering the font.
    await font.loadTexture(textureName);
    registerFont(fontName, font);

    // Font is loaded, so remove it from the in progress map
    _fontsInProgress.remove(fontName);
  }

  /// A convenience method to create and register the default font for the application.
  Future<void> createDefaultFont() async {
    await createFont("default", creatoDisplayBoldXml, "CreatoDisplay-Bold.png");
  }
}

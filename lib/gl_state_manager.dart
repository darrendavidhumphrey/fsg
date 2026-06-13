import 'fsg_singleton.dart';

class GlStateManager {

  GlStateManager();

  // Must be called before rendering a scene
  void startFrame()  {
    FSG().textureManager.bindUnboundTextures();
  }
}
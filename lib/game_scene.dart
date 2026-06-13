import 'package:flutter_angle/flutter_angle.dart';
import 'package:vector_math/vector_math_64.dart';
import 'fsg.dart';
import 'game_scene_data.dart';
import 'game_scene_nodes.dart';

class GameScene extends Scene {
  final GameSceneData data;
  final List<GameSceneNode> rootNodes = [];
  final Map<String, GameSceneNode> nodeMap = {};
  final Map<String, WebGLTexture> textureMap = {};

  GameScene(this.data);

  @override
  Future<void> init(RenderingContext gl) async {
    super.init(gl);

    // 1. Load textures
    for (var textureData in data.textures.values) {
      final tex = await FSG().textureManager.createTextureFromAsset(
          textureData.file);
    }

    // 2. Load fonts
    for (var fontData in data.fonts.values) {
      // Assuming BitmapFontManager has a way to load from asset strings, 
      // but the current implementation of createFont uses hardcoded asset logic.
      // For now, we assume fonts are already registered or we'd need to fetch their XML.
      // This part might need more robust asset loading.

      // TODO: Implement this
    }

    // 3. Build node tree
    for (var objData in data.objects) {
      final node = _createNode(objData);
      if (node != null) {
        rootNodes.add(node);
      }
    }

    // 4. Initialize nodes
    for (var node in rootNodes) {
      node.init(gl);
    }

    // 5. Assign textures to quads
    _assignTextures();
    
    // Orthographic projection for 2D UI
    pMatrix = makeOrthographicMatrix(0, 1280, 720, 0, -1, 1);
  }

  void _assignTextures() {
    for (var node in nodeMap.values) {
      if (node is GameQuadNode) {
        final quadData = node.data as QuadData;
        node.texture = textureMap[quadData.texture];
      }
    }
  }

  GameSceneNode? _createNode(SceneObject objData) {
    GameSceneNode? node;
    if (objData is GroupData) {
      final groupNode = GameGroupNode(objData);
      for (var childData in objData.children) {
        final childNode = _createNode(childData);
        if (childNode != null) {
          groupNode.children.add(childNode);
        }
      }
      node = groupNode;
    } else if (objData is QuadData) {
      node = GameQuadNode(objData);
    } else if (objData is TextData) {
      node = GameTextNode(objData);
    }

    if (node != null) {
      nodeMap[objData.id] = node;
    }
    return node;
  }

  @override
  void drawScene() {
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    gl.disable(WebGL.DEPTH_TEST);
    gl.enable(WebGL.BLEND);
    gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE_MINUS_SRC_ALPHA);

    mvMatrixStack.current = Matrix4.identity();
    for (var node in rootNodes) {
      node.draw(gl, pMatrix, mvMatrixStack);
    }
  }

  @override
  void dispose() {
    for (var node in rootNodes) {
      node.dispose();
    }
    super.dispose();
  }

  GameSceneNode? findNode(String id) => nodeMap[id];

  void setVisible(String id, bool visible) {
    findNode(id)?.visible = visible;
  }

  void setText(String id, String text) {
    final node = findNode(id);
    if (node is GameTextNode) {
      node.bitmapText?.setText(text);
    }
  }
}

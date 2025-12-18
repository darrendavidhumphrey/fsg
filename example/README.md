# FSG - Flutter Scene Graph
A lightweight package for integrating interactive 3D content into your flutter apps. FSG is a layer on top of the the flutter_angle package.
## Why Does This Package Exist?
As of 2025, Flutter STILL has no officially sanctioned method to integrate performant, cross-platform interactive 3D content into flutter apps. 
While Flutter_angle provides a low level API conformant with OpenGL ES, there is still quite a lot of additional code required to create interactive 3D content. 
FSG simplifies integrating such content into flutter apps by providing a reusable framework to automate much of the drudgery.

FSG provides:
* Management of OpenGL resources like Index Buffers, Vertex Buffers, Shaders, Textures and Materials
* Efficient loading of vertex data using native buffers
* A framework to create custom shaders with type-safe access to uniforms from dart 
* Widgets for integrating real-time animated scenes into the flutter widget hierarchy
* Integration of pointer and touch events into 3D scenes using NavigationDelegates
* A sample OrbitView NavigationDelegate
* A framework for rendering scenes in multiple layers and combining them
* A BitMap font system for creating simple 2D texture mapped text that can be drawn inside FSG scenes

Additionally, FSG supplies supporting code for:
* Triangle level 3D picking of geometry using ray casting
* Operations for clipping polylines, and tessellating them into triangle meshes
* Simple Wavefront OBJ file loader
* A set of example applications demonstrating most features 
## Getting Started
To use FSG, add it to your pubspec
```
 $ flutter pub add fsg
```

Include FSG in your main, and initialize the library

```
import 'package:fsg/fsg.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the FSG library in main, after WidgetsFlutterBinding.ensureInitialized();
  FSG().initPlatformState();
  
  ...
  
}
```
Then create a custom subclass of Scene to contain your custom rendering code. 

```
class MyCustomScene extends Scene {
...
}
```
Instantiate that scene somewhere exactly once. In this example, the scene is instantiated in the initState method in a StatefulWidget.
After instantiating the Scene, register the scene with FSG using registerSceneAndAllocateTexture.

FSG renders scenes to a texture in a background operation, using SingleTickerProviderStateMixin to draw the 3D scene at whatever frame rate the application is running at. 
The RenderToTexture widget then composites the rendered output into the flutter_app.

```
class TestAppState extends State<TestApp> {
late MyCustomScene myScene;

  @override
  void initState() {
    super.initState();
    myScene = MyCustomScene();
    FSG().registerSceneAndAllocateTexture(myScene);
  }
```
Finally, somewhere in your widget tree, place the 3D scene using RenderToTexture

```
Scaffold(body: RenderToTexture(scene: myScene));
```

Alternatively, use InteractiveRenderToTexture, which takes a second argument of a NavigationDelegate.
InteractiveRenderToTexture creates a GestureRecognizer and a Listener and passes pointer and touch events to the navigation delegate. 
The navigation delegate then creates modelview and projection matrices to control the view of the InteractiveRenderToTexture widget.

In this example, the FSG provided OrbitView navigation delegate is used, which allows the user to spin the view using mouse/touch events.
You can create your own custom NavigationDelegates to do whatever kind of navigation/interaction you need.
```
  late MyCustomScene myScene;
  late OrbitView orbitView;
  @override
  void initState() {
    super.initState();
    myScene = MyCustomScene();
    orbitView = OrbitView();
    FSG().registerSceneAndAllocateTexture(myScene);
  }

Scaffold(body: InteractiveRenderToTexture(
    navigationDelegate: orbitView
    scene: myScene));
```

You may instantiate multiple custom scenes and register them with FSG. You may place multiple RenderToTexture widgets in your app.
By default, FSG also detects when a scene is not visible and pauses its rendering output. 

## Contributing
FSG is in its very early development stages and is being developed to support my personal projects. 
Contributions on all fronts are welcomed, please contact me if you want to help out.
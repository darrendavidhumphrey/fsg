import 'package:flutter/material.dart';
import 'package:fsk/fsk.dart';

import 'checkerboard_scene.dart';
import 'orbitview_scene.dart';

class MultipleSceneExample extends StatefulWidget {
  final bool isPaused;
  const MultipleSceneExample({super.key,this.isPaused = true});

  @override
  MultipleSceneExampleState createState() => MultipleSceneExampleState();
}

class MultipleSceneExampleState extends State<MultipleSceneExample> {
  FskScene? scene1, scene2;
  bool loading = true;

  Future<void> initScenes(double dpr) async {
    scene1 = OrbitViewScene(navigationDelegate: OrbitViewDelegate());
    scene2 = CheckerBoardScene(navigationDelegate: OrbitViewDelegate());
    // Assign the initial constructor configuration state to the engine instances
    scene1!.isPaused = widget.isPaused;
    scene2!.isPaused = widget.isPaused;
    await FSK().registerSceneAndAllocateTexture(scene1!, dpr: dpr);
    await FSK().registerSceneAndAllocateTexture(scene2!, dpr: dpr);

    // Trigger a rebuild of the widget
    setState(() {
      loading = false;
    });
  }

  @override
  void didUpdateWidget(covariant MultipleSceneExample oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPaused != widget.isPaused) {
      setPaused(widget.isPaused);
    }
  }

  // Method to actively control and pass the execution states to the FSK engine
  void setPaused(bool paused) {
    if (scene1 != null && scene2 != null) {
      setState(() {
        scene1!.isPaused = paused;
        scene2!.isPaused = paused;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (scene1 == null || scene2 == null) {
          initScenes(MediaQuery.of(context).devicePixelRatio);
          return const CircularProgressIndicator();
        }

        return Scaffold(
          body: Row(
            children: [
              // Left side - takes up exactly half the screen width
              Expanded(
                child: Container(
                  color: Colors.blueGrey.shade900,
                  child: Center(
                    child: Stack(
                      children: [
                        RenderToTexture(scene: scene1!),
                        const Text(
                          'Scene 1 (Left Half)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Right side - takes up exactly half the screen width
              Expanded(
                child: Container(
                  color: Colors.blueGrey.shade900,
                  child: Center(
                    child: Stack(
                      children: [
                        RenderToTexture(scene: scene2!),
                        const Text(
                          'Scene 2 (Right Half)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

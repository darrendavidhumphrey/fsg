import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../frame_counter.dart';
import '../fsg_singleton.dart';
import '../scene.dart';
import '../logging.dart';

class RenderToTexture extends StatefulWidget {
  final Scene scene;
  final bool automaticallyPause;
  const RenderToTexture({
    required this.scene,
    super.key,
    this.automaticallyPause = true,
  });
  @override
  RenderToTextureState createState() => RenderToTextureState();
}

class RenderToTextureState extends State<RenderToTexture>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin, LoggableClass {
  Size screenSize = Size.zero;
  bool windowResized = false;
  Ticker? ticker;
  final Key _pauseKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.automaticallyPause) {
      widget.scene.isPaused = true;
    }
  }

  @override
  void dispose() {
    if (ticker != null) {
      ticker!.dispose();
    }
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeMetrics() {
    onWindowResize(context);
  }

  Future<void> onWindowResize(BuildContext context) async {
    windowResized = true;
    widget.scene.requestRepaint();
  }

  @override
  Widget build(BuildContext context) {
    return
  ChangeNotifierProvider.value(
        value: FSG().frameCounter,
        child: Consumer<FrameCounterModel>(
          builder: (context, counter, child) {
            return
              VisibilityDetector(
                  key: _pauseKey,
                  onVisibilityChanged: (visibilityInfo) {
                    if (widget.automaticallyPause) {
                      bool visible = (visibilityInfo.visibleFraction > 0);
                      widget.scene.isPaused = !visible;
                    }
                  },
                  child:
              LayoutBuilder(
              builder: (context, constraints) {
                FlutterAngleTexture? textureId = FSG().scenes[widget.scene];

                if (textureId != null) {
                  bool firstPaint = !widget.scene.isInitialized;
                  if (firstPaint) {
                    FSG().initScene(context, widget.scene);

                    logTrace(
                      "Start RenderToTexture Ticker for scene of type ${widget.scene.runtimeType}",
                    );
                    ticker = createTicker(widget.scene.renderSceneToTexture);
                    ticker!.start();
                  }

                  if (firstPaint || windowResized) {
                    windowResized = false;
                    screenSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    widget.scene.setViewportSize(screenSize);
                    logTrace("Viewport size is ${screenSize.toString()}");
                  }
                } else {
                  logPedantic("Adding post frame callback to refresh texture");
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    logTrace(
                      "Scheduling a refresh because texture is not initialized",
                    );

                    FSG().registerSceneAndAllocateTexture(widget.scene);
                    Provider.of<FrameCounterModel>(
                      context,
                      listen: false,
                    ).increment();
                  });
                }
                if (widget.scene.renderToTextureId == null) {
                  return Container();
                }
                return Texture(
                  textureId: widget.scene.renderToTextureId!.textureId,
                  filterQuality: FilterQuality.medium,
                );
              },
              ));
          },
        ),
    );
  }
}

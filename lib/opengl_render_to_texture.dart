import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle/desktop/angle.dart';
import 'package:provider/provider.dart';
import 'frame_counter.dart';
import 'gl_common/flutter_angle_manager.dart';
import 'gl_common/opengl_scene.dart';
import 'logging.dart';

class OpenGLRenderToTextureWidget extends StatefulWidget {
  final OpenGLScene scene;
  const OpenGLRenderToTextureWidget({required this.scene, super.key});
  @override
  OpenGLRenderToTextureWidgetState createState() =>
      OpenGLRenderToTextureWidgetState();
}

class OpenGLRenderToTextureWidgetState
    extends State<OpenGLRenderToTextureWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin, LoggableClass {
  Size screenSize = Size.zero;
  bool windowResized = false;
  Ticker? ticker;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    widget.scene.forceRepaint = true;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: FlutterAngleManager().frameCounter,
      child: Consumer<FrameCounterModel>(
        builder: (context, counter, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              FlutterAngleTexture? textureId = FlutterAngleManager().scenes[widget.scene];

              if (textureId != null) {
                bool firstPaint = !widget.scene.isInitialized;
                if (firstPaint) {
                  FlutterAngleManager().initScene(context, widget.scene);

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

                  FlutterAngleManager().allocTextureForScene(widget.scene);
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
          );
        },
      ),
    );
  }
}

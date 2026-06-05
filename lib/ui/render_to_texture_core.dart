import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle/flutter_angle.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../fsg_singleton.dart';
import '../scene.dart';
import '../logging.dart';

class RenderToTextureCore extends StatefulWidget {
  final Scene scene;
  final bool automaticallyPause;
  final Widget? child;
  // Added: Accepts a notifier from the parent to signal frame repaints
  final ValueNotifier<int>? repaintNotifier;

  const RenderToTextureCore({
    super.key,
    required this.scene,
    this.automaticallyPause = true,
    this.child,
    this.repaintNotifier,
  });

  @override
  RenderToTextureCoreState createState() => RenderToTextureCoreState();
}

class RenderToTextureCoreState extends State<RenderToTextureCore>
    with WidgetsBindingObserver, TickerProviderStateMixin, LoggableClass {
  Size screenSize = Size.zero;
  Ticker? ticker;
  final Key _visibilityKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.automaticallyPause) {
      widget.scene.isPaused = true;
    }
    _initRenderLoop();
  }

  void _initRenderLoop() async {
    if (kIsWeb) {
      // Safely let the browser DOM register the viewType before ticking
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {});
      }
    }
    // Guarantees exactly ONE ticker is ever created
    ticker ??= createTicker(_onHardwareTick)..start();
  }

  @override
  void dispose() {
    ticker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    onWindowResize();
  }

  void onWindowResize() {
    widget.scene.requestRepaint();
  }

  void _onHardwareTick(Duration elapsed) async {
    if (widget.scene.frameProcessing) {
      return;
    }

    await widget.scene.renderSceneToTexture();

    if (mounted) {
      if (!kIsWeb) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: (visibilityInfo) {
        if (widget.automaticallyPause) {
          bool visible = (visibilityInfo.visibleFraction > 0);
          widget.scene.isPaused = !visible;
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          FlutterAngleTexture? texture = FSG().scenes[widget.scene];

          screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          widget.scene.setViewportSize(screenSize);

          return Stack(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: kIsWeb
                    ? HtmlElementView(
                        key: ValueKey(texture!.textureId),
                        viewType: texture!.textureId.toString(),
                      )
                    : Texture(
                        key: ValueKey(texture!.textureId),
                        textureId: texture!.textureId,
                        filterQuality: FilterQuality.medium,
                      ),
              ),
              widget.child!,
            ],
          );
        },
      ),
    );
  }
}

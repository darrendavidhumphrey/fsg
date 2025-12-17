import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_angle_jig/gl_common/scene.dart';
import 'package:flutter_angle_jig/ui/render_to_texture.dart';
import 'package:flutter_angle_jig/ui/angle_scene_navigation_delegate.dart';
import 'package:visibility_detector/visibility_detector.dart';

class InteractiveRenderToTexture extends StatefulWidget {
  final Scene scene;
  final AngleSceneNavigationDelegate navigationDelegate;
  final bool automaticallyPause;
  const InteractiveRenderToTexture({
    super.key,
    this.automaticallyPause = true,
    required this.scene,
    required this.navigationDelegate,
  });

  @override
  OrbitViewState createState() => OrbitViewState();
}

class OrbitViewState extends State<InteractiveRenderToTexture> {
  late FocusNode _focusNode;
  final Key _pauseKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.automaticallyPause) {
      widget.scene.isPaused = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.navigationDelegate.setScene(widget.scene);

    // TODO: Force the initial update
    // TODO: Handle all other events

    return VisibilityDetector(
      key: _pauseKey,
      onVisibilityChanged: (visibilityInfo) {
        if (widget.automaticallyPause) {
          bool visible = (visibilityInfo.visibleFraction > 0);
          widget.scene.isPaused = !visible;
        }
      },
      child: GestureDetector(
        onTapDown: (TapDownDetails event) {
          widget.navigationDelegate.onTapDown(event);
        },
        child: Focus(
          autofocus: true,
          focusNode: _focusNode,
          onKeyEvent: (node, event) {
            // TODO: Handle keyboard event
            return KeyEventResult.ignored;
          },
          child: Listener(
            onPointerSignal: (event) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
              if (event is PointerScrollEvent) {
                widget.navigationDelegate.onPointerScroll(event);
              }
            },

            onPointerMove: (event) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
              widget.navigationDelegate.onPointerMove(event);
            },

            child: RenderToTexture(scene: widget.scene),
          ),
        ),
      ),
    );
  }
}



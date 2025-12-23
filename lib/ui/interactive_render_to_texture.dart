import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fsg/scene.dart';
import 'package:fsg/ui/render_to_texture_core.dart';
import 'package:fsg/ui/scene_navigation_delegate.dart';

/// A widget that renders a [Scene] and provides user interaction capabilities.
///
/// This widget builds upon [RenderToTextureCore] by adding a [GestureDetector],
/// a [Listener] for mouse events, and a [Focus] widget for keyboard events.
/// It forwards all user input to a [SceneNavigationDelegate] to control the scene.
class InteractiveRenderToTexture extends StatefulWidget {
  /// The scene to be rendered.
  final Scene scene;

  /// The delegate responsible for handling user input and navigating the scene.
  final SceneNavigationDelegate? navigationDelegate;

  /// If true, the scene will automatically pause when it is not visible.
  final bool automaticallyPause;

  const InteractiveRenderToTexture({
    super.key,
    this.automaticallyPause = true,
    required this.scene,
    this.navigationDelegate,
  });

  @override
  InteractiveRenderToTextureState createState() =>
      InteractiveRenderToTextureState();
}

class InteractiveRenderToTextureState
    extends State<InteractiveRenderToTexture> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Set the scene on the delegate when the widget is first created.
    widget.navigationDelegate?.setScene(widget.scene);
  }

  @override
  void didUpdateWidget(covariant InteractiveRenderToTexture oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the scene or delegate changes, update the delegate.
    if (widget.scene != oldWidget.scene ||
        widget.navigationDelegate != oldWidget.navigationDelegate) {
      widget.navigationDelegate?.setScene(widget.scene);
    }
  }

  @override
  void dispose() {
    // Dispose the FocusNode to prevent memory leaks.
    widget.navigationDelegate?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The core rendering widget, wrapped with interaction listeners.
    final core = RenderToTextureCore(
      scene: widget.scene,
      automaticallyPause: widget.automaticallyPause,
      // The child is a Listener that captures all user input.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          // Request focus on tap down to enable keyboard events.
          _focusNode.requestFocus();
          widget.navigationDelegate?.onPointerDown(event);
        },
        onPointerUp: (event) {
          widget.navigationDelegate?.onPointerUp(event);
        },
        onPointerCancel: (event) {
          widget.navigationDelegate?.onPointerCancel(event);
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            widget.navigationDelegate?.onPointerScroll(event);
          }
        },
        onPointerMove: (event) {
          widget.navigationDelegate?.onPointerMove(event);
        },
      ),
    );

    // The Focus widget wraps everything to capture keyboard events.
    return Focus(
      autofocus: widget.navigationDelegate != null,
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        return widget.navigationDelegate?.onKeyEvent(event) ??
            KeyEventResult.ignored;
      },
      child: core,
    );
  }
}

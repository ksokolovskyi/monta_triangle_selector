// ignore_for_file: prefer_asserts_with_message, cascade_invocations

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:monta_triangle_selector/triangle_model.dart';
import 'package:monta_triangle_selector/triangle_selector_value.dart';

/// {@template triangle_selector}
/// Selector that is used to adjust the distribution of percentages among
/// three vertices of a triangle using a single draggable thumb.
/// {@endtemplate}
class TriangleSelector extends StatelessWidget {
  /// {@macro triangle_selector}
  const TriangleSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The currently selected percentage values for this slider.
  final TriangleSelectorValue value;

  /// Called during a drag when the user is selecting a new value for the slider
  /// by dragging.
  ///
  /// The slider passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the slider with the new
  /// value.
  ///
  /// If null, the slider will be disabled.
  final ValueChanged<TriangleSelectorValue>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _TriangleSelector(
      value: value,
      onChanged: onChanged,
      thumb: const _Thumb(),
      tapPicture: const _TapPicture(),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x193FBB85),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF3FBB85),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.5),
              child: SvgPicture.asset(
                'assets/images/bolt.svg',
                fit: BoxFit.fitHeight,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapPicture extends StatelessWidget {
  const _TapPicture();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/tap.svg',
      colorFilter: const ColorFilter.mode(
        Color(0x99C8C8C8),
        BlendMode.srcIn,
      ),
    );
  }
}

enum _TriangleSelectorSlot {
  thumb,
  tapPicture,
}

class _TriangleSelector extends SlottedMultiChildRenderObjectWidget<
    _TriangleSelectorSlot, RenderBox> {
  const _TriangleSelector({
    required this.value,
    required this.onChanged,
    required this.thumb,
    required this.tapPicture,
  });

  final TriangleSelectorValue value;

  final ValueChanged<TriangleSelectorValue>? onChanged;

  final Widget thumb;

  final Widget tapPicture;

  @override
  Iterable<_TriangleSelectorSlot> get slots => _TriangleSelectorSlot.values;

  @override
  Widget? childForSlot(_TriangleSelectorSlot slot) {
    return switch (slot) {
      _TriangleSelectorSlot.thumb => thumb,
      _TriangleSelectorSlot.tapPicture => tapPicture,
    };
  }

  @override
  SlottedContainerRenderObjectMixin<_TriangleSelectorSlot, RenderBox>
      createRenderObject(BuildContext context) {
    return _RenderTriangleSelector(
      value: value,
      onChanged: onChanged,
      gestureSettings: MediaQuery.gestureSettingsOf(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTriangleSelector renderObject,
  ) {
    renderObject
      ..value = value
      ..onChanged = onChanged
      ..gestureSettings = MediaQuery.gestureSettingsOf(context);
  }
}

class _RenderTriangleSelector extends RenderShiftedBox
    with SlottedContainerRenderObjectMixin<_TriangleSelectorSlot, RenderBox>
    implements MouseTrackerAnnotation {
  _RenderTriangleSelector({
    required TriangleSelectorValue value,
    required ValueChanged<TriangleSelectorValue>? onChanged,
    required DeviceGestureSettings gestureSettings,
    RenderBox? child,
  })  : _value = value,
        _onChanged = onChanged,
        _cursor = SystemMouseCursors.click,
        super(child) {
    final team = GestureArenaTeam();
    _drag = PanGestureRecognizer()
      ..team = team
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _endInteraction
      ..gestureSettings = gestureSettings;
    _tap = TapGestureRecognizer()
      ..team = team
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..onTapCancel = _endInteraction
      ..gestureSettings = gestureSettings;
  }

  /// The max allowed size for the selector.
  static const _additionalConstraints = BoxConstraints(
    maxHeight: 300,
    maxWidth: 300,
  );

  /// The selector aspect ratio is set to 1, so the width will be equal to the
  /// height.
  static const _aspectRatio = 1.0;

  late PanGestureRecognizer _drag;
  late TapGestureRecognizer _tap;

  /// This size is used to cache the TriangleModel and to recalculate it only if
  /// size was changed.
  Size? _cachedSize;
  TriangleModel? _triangleModel;

  Offset _currentDragValue = Offset.zero;

  TriangleSelectorValue get value => _value;
  TriangleSelectorValue _value;
  set value(TriangleSelectorValue value) {
    if (value == _value) {
      return;
    }
    _value = value;
    markNeedsPaint();
  }

  ValueChanged<TriangleSelectorValue>? get onChanged => _onChanged;
  ValueChanged<TriangleSelectorValue>? _onChanged;
  set onChanged(ValueChanged<TriangleSelectorValue>? value) {
    if (value == _onChanged) {
      return;
    }
    _onChanged = value;
  }

  bool get isInteractive => _onChanged != null;

  DeviceGestureSettings? get gestureSettings => _drag.gestureSettings;
  set gestureSettings(DeviceGestureSettings? gestureSettings) {
    _drag.gestureSettings = gestureSettings;
    _tap.gestureSettings = gestureSettings;
  }

  @override
  MouseCursor get cursor => _cursor;
  MouseCursor _cursor;
  set cursor(MouseCursor value) {
    if (_cursor != value) {
      _cursor = value;
      // A repaint is needed in order to trigger a device update of
      // [MouseTracker] so that this new value can be found.
      markNeedsPaint();
    }
  }

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => null;

  @override
  bool get validForMouseTracker => true;

  @override
  bool get isRepaintBoundary => true;

  RenderBox get _thumb => childForSlot(_TriangleSelectorSlot.thumb)!;
  RenderBox get _tapPicture => childForSlot(_TriangleSelectorSlot.tapPicture)!;

  @override
  void dispose() {
    _drag.dispose();
    _tap.dispose();
    super.dispose();
  }

  @override
  bool hitTestSelf(Offset position) {
    assert(() {
      _debugAssertTriangleModelInitialized();
      return true;
    }());

    // Checks whether event position is inside the rounded triangle shape.
    return _triangleModel!.path.contains(position);
  }

  /// Checks whether event position is on the thumb.
  bool _hitTestThumb(BoxHitTestResult result, {required Offset position}) {
    final thumbParentData = _boxParentData(_thumb);

    return result.addWithPaintOffset(
      offset: thumbParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - thumbParentData.offset);
        return _thumb.hitTest(result, position: transformed);
      },
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!isInteractive) {
      return false;
    }

    if (_hitTestThumb(result, position: position) ||
        (size.contains(position) && hitTestSelf(position))) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    return false;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    if (event is PointerDownEvent && isInteractive) {
      // We need to add the drag first so that it has priority.
      _drag.addPointer(event);
      _tap.addPointer(event);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _startInteraction(details.localPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _currentDragValue += details.delta;
    cursor = SystemMouseCursors.grabbing;

    onChanged!(_getValueFromLocalPosition(_currentDragValue));
  }

  void _handleDragEnd(DragEndDetails details) {
    _endInteraction();
  }

  void _handleTapDown(TapDownDetails details) {
    _startInteraction(details.localPosition);
  }

  void _handleTapUp(TapUpDetails details) {
    _endInteraction();
  }

  /// Converts [localPosition] of the thumb into the [TriangleSelectorValue].
  TriangleSelectorValue _getValueFromLocalPosition(Offset localPosition) {
    assert(() {
      _debugAssertTriangleModelInitialized();
      return true;
    }());

    final triangleModel = _triangleModel!;

    final point = triangleModel.clampPointInsideTriangle(_currentDragValue);

    return triangleModel.valueFromPoint(point);
  }

  void _startInteraction(Offset localPosition) {
    assert(() {
      _debugAssertTriangleModelInitialized();
      return true;
    }());

    final didHitThumb = _hitTestThumb(
      BoxHitTestResult(),
      position: localPosition,
    );

    // If the gesture was started on the thumb then don't jump to the new
    // position.
    if (didHitThumb) {
      _currentDragValue = _triangleModel!.pointFromValue(value);
    } else {
      _currentDragValue = localPosition;
    }

    onChanged!(_getValueFromLocalPosition(_currentDragValue));
  }

  void _endInteraction() {
    cursor = SystemMouseCursors.click;
    _currentDragValue = Offset.zero;
  }

  Size _applyAspectRatio(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    assert(() {
      if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight) {
        throw FlutterError(
          '$runtimeType has unbounded constraints.\n'
          'This $runtimeType was given an aspect ratio of $_aspectRatio but '
          'was given both unbounded width and unbounded height constraints. '
          'Because both constraints were unbounded, this render object '
          "doesn't know how much size to consume.",
        );
      }
      return true;
    }());

    if (constraints.isTight) {
      return constraints.smallest;
    }

    var width = constraints.maxWidth;
    double height;

    // We default to picking the height based on the width, but if the width
    // would be infinite, that's not sensible so we try to infer the height
    // from the width.
    if (width.isFinite) {
      height = width / _aspectRatio;
    } else {
      height = constraints.maxHeight;
      width = height * _aspectRatio;
    }

    // Similar to RenderImage, we iteratively attempt to fit within the given
    // constraints while maintaining the given aspect ratio. The order of
    // applying the constraints is also biased towards inferring the height
    // from the width.
    if (width > constraints.maxWidth) {
      width = constraints.maxWidth;
      height = width / _aspectRatio;
    }

    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * _aspectRatio;
    }

    if (width < constraints.minWidth) {
      width = constraints.minWidth;
      height = width / _aspectRatio;
    }

    if (height < constraints.minHeight) {
      height = constraints.minHeight;
      width = height * _aspectRatio;
    }

    return constraints.constrain(Size(width, height));
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return _applyAspectRatio(_additionalConstraints.enforce(constraints));
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    size = computeDryLayout(constraints);

    _createTriangleModelIfNeeded(size);

    assert(() {
      _debugAssertTriangleModelInitialized();
      return true;
    }());

    _thumb.layout(
      BoxConstraints(maxWidth: size.width / 2.5),
    );

    final triangleModel = _triangleModel!;
    final maxTapPictureHeight =
        (triangleModel.bounds.bottom - triangleModel.center.dy) * 0.75;

    _tapPicture.layout(
      BoxConstraints(maxHeight: maxTapPictureHeight),
    );
  }

  /// Creates a new [TriangleModel] if this is the first layout or if the size
  /// changed.
  void _createTriangleModelIfNeeded(Size size) {
    if (size == _cachedSize && _triangleModel != null) {
      return;
    }

    _cachedSize = size;

    final rect = Offset.zero & size;
    final radius = rect.width * 8.0 / _additionalConstraints.maxWidth;

    _triangleModel = TriangleModel.fromRectAndRadius(rect, radius);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(() {
      _debugAssertTriangleModelInitialized();
      return true;
    }());

    final triangleModel = _triangleModel!;

    final canvas = context.canvas;

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF1F1F1),
          Color(0xFFF9F9F9),
          Color(0xFFFEFEFE),
        ],
        stops: [0, 0.5, 1],
      ).createShader(triangleModel.bounds)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFC8C8C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // Drawing rounded triangle.
    canvas.drawPath(triangleModel.path, backgroundPaint);
    canvas.drawPath(triangleModel.path, borderPaint);

    // Drawing lines from vertices to center.
    borderPaint.color = const Color(0xFFE1E1E1);
    canvas.drawLine(triangleModel.aRounded, triangleModel.center, borderPaint);
    canvas.drawLine(triangleModel.bRounded, triangleModel.center, borderPaint);
    canvas.drawLine(triangleModel.cRounded, triangleModel.center, borderPaint);

    canvas.restore();

    // Drawing tap picture.
    final tapPictureSize = _tapPicture.size;
    context.paintChild(
      _tapPicture,
      triangleModel.center.translate(
            -tapPictureSize.width / 2,
            -tapPictureSize.height * 0.15,
          ) +
          offset,
    );

    /// Drawing thumb.
    final thumbPosition = triangleModel.pointFromValue(value);
    final thumbSize = _thumb.size;
    final thumbParentData = _boxParentData(_thumb);
    thumbParentData.offset = thumbPosition.translate(
      -thumbSize.width / 2,
      -thumbSize.height / 2,
    );
    context.paintChild(_thumb, thumbParentData.offset + offset);
  }

  static BoxParentData _boxParentData(RenderBox box) =>
      box.parentData! as BoxParentData;

  void _debugAssertTriangleModelInitialized() {
    if (_triangleModel == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('The _triangleData was not initialized.'),
        ErrorDescription(
          'It appears that in a place where the _triangleData was needed it '
          'was not initialized.',
        ),
      ]);
    }
  }
}

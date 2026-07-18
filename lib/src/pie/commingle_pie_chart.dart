import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../commingle_charts_animation.dart';
import 'commingle_pie_chart_controller.dart';
import 'commingle_pie_slice.dart';

const awesomePieChartDefaultBadgeDiameter = 28.0;
const awesomePieChartDefaultRingThickness = 56.0;
const awesomePieChartDefaultPressedGrowth = 8.0;

const _sectionsSpaceDegrees = 2.5;
const _rootStartOffset = -90.0;

/// Interactive multi-level pie chart.
///
/// Resting state is always a single pie for the current depth. During a drill
/// transition a second pie is stacked on top; when the transition completes the
/// overlay is dropped and the single pie shows the new level.
final class ComminglePieChart extends StatefulWidget {
  final List<ComminglePieSlice> slices;
  final ComminglePieChartController? controller;

  /// Drives the drill-in / drill-out (level transition) animation.
  final CommingleChartsAnimation animation;
  final double badgeDiameter;

  /// Thickness (in logical pixels) of the painted ring.
  final double ringThickness;

  /// How far (in logical pixels) a slice's outer edge grows while it is pressed.
  ///
  /// The pressed slice draws beyond the widget's bounds via fl_chart's overdraw;
  /// wrap the chart in your own [Padding] if you need to reserve space for it.
  final double pressedGrowth;

  /// Animates the pressed-slice growth (and shrink on release).
  ///
  /// Provide both a duration and curve to animate; leave null for an instant
  /// grow/shrink.
  final CommingleChartsAnimation? pressGrowthAnimation;

  /// Section sweep (radians) at/above which a badge is full size (angle₂).
  final double? fullIconSweep;

  /// Section sweep (radians) at which a badge is half size (angle₁).
  final double? minIconSweep;

  const ComminglePieChart({
    super.key,
    required this.slices,
    this.controller,
    this.animation = const CommingleChartsAnimation(
      duration: Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    ),
    this.badgeDiameter = awesomePieChartDefaultBadgeDiameter,
    this.ringThickness = awesomePieChartDefaultRingThickness,
    this.pressedGrowth = awesomePieChartDefaultPressedGrowth,
    this.pressGrowthAnimation,
    this.fullIconSweep,
    this.minIconSweep,
  });

  @override
  State<ComminglePieChart> createState() => _ComminglePieChartState();
}

final class _ComminglePieChartState extends State<ComminglePieChart> with SingleTickerProviderStateMixin {
  late final AnimationController _expansion;

  /// Committed drill path into the chart data.
  final List<int> _path = [];

  /// Start-degree offset for the resting pie at each depth (`_offsetStack.length == _path.length + 1`).
  final List<double> _offsetStack = [_rootStartOffset];

  /// When non-null, a drill transition is active for this index of the current level.
  int? _drillIndex;
  int? _hotIndex;
  bool _drillForward = true;

  @override
  void initState() {
    super.initState();
    _expansion = AnimationController(
      vsync: this,
      duration: widget.animation.duration,
    )..addStatusListener(_onExpansionStatus);
    widget.controller?.attach(
      reset: _reset,
      collapse: _collapse,
      expand: _expand,
    );
    _syncControllerPath();
  }

  bool get _isBusy => _drillIndex != null || _expansion.isAnimating;

  /// Finish any in-flight transition immediately, committing its end state.
  void _settle() {
    if (_drillIndex == null) return;
    // Fires _onExpansionStatus synchronously: completed -> commit new level,
    // dismissed -> drop the collapse overlay.
    _expansion.value = _drillForward ? 1.0 : 0.0;
  }

  List<ComminglePieSlice> get _currentSlices => _slicesAtPath(_path);

  double get _currentStartOffset => _offsetStack.last;

  /// Indices listeners should see: include an in-flight forward drill immediately.
  List<int> get _effectivePathIndices {
    if (_drillIndex case final drillIndex? when _drillForward) {
      return [..._path, drillIndex];
    }
    return List<int>.of(_path);
  }

  List<ComminglePieSlice> _slicesAtPath(List<int> path) {
    var slices = widget.slices;
    for (final index in path) {
      if (index < 0 || index >= slices.length) return const [];
      final next = slices[index];
      if (!next.hasChildren) return [next];
      slices = next.slices;
    }
    return slices;
  }

  /// Slice objects along [indices] (one per path step), or empty if invalid.
  List<ComminglePieSlice> _slicesAlongIndices(List<int> indices) {
    if (indices.isEmpty) return const [];
    final result = <ComminglePieSlice>[];
    var slices = widget.slices;
    for (final index in indices) {
      if (index < 0 || index >= slices.length) return const [];
      final next = slices[index];
      result.add(next);
      if (!next.hasChildren) break;
      slices = next.slices;
    }
    return result;
  }

  void _syncControllerPath() {
    widget.controller?.updatePath(_slicesAlongIndices(_effectivePathIndices));
  }

  void _onExpansionStatus(AnimationStatus status) {
    if (!mounted) return;

    if (status == AnimationStatus.completed && _drillIndex != null && _drillForward) {
      final index = _drillIndex!;
      final slices = _currentSlices;
      if (index < 0 || index >= slices.length) return;

      final t = widget.animation.curve.transform(1);
      final values = _expandedParentValues(slices, index, t);
      final midpoint = _restingMidpoint(slices, index, startOffset: _currentStartOffset);
      final offset = _offsetKeepingMidpoint(values, index, midpoint);

      setState(() {
        _path.add(index);
        _offsetStack.add(offset);
        _drillIndex = null;
        _hotIndex = null;
      });
      _expansion.value = 0;
      // Path content unchanged (already notified at expand start).
      return;
    }

    if (status == AnimationStatus.dismissed && _drillIndex != null) {
      setState(() {
        _drillIndex = null;
        _hotIndex = null;
        _drillForward = true;
      });
      // Path already shortened when reverse started.
    }
  }

  @override
  void didUpdateWidget(ComminglePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(
        reset: _reset,
        collapse: _collapse,
        expand: _expand,
      );
      widget.controller?.attach(
        reset: _reset,
        collapse: _collapse,
        expand: _expand,
      );
      _syncControllerPath();
    }
    if (oldWidget.animation.duration != widget.animation.duration) {
      _expansion.duration = widget.animation.duration;
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(
      reset: _reset,
      collapse: _collapse,
      expand: _expand,
    );
    _expansion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final fullIconSweep =
            widget.fullIconSweep ??
            awesomePieChartFullIconSweep(
              size: size,
              badgeDiameter: widget.badgeDiameter,
              ringThickness: widget.ringThickness,
            );
        final minIconSweep = widget.minIconSweep ?? fullIconSweep / 2;

        if (_drillIndex case final drillIndex?) {
          return AnimatedBuilder(
            animation: _expansion,
            builder: (context, _) {
              return _ExpandFrame(
                slices: _currentSlices,
                progress: widget.animation.curve.transform(_expansion.value),
                selectedIndex: drillIndex,
                size: size,
                startOffset: _currentStartOffset,
                minIconSweep: minIconSweep,
                fullIconSweep: fullIconSweep,
                badgeDiameter: widget.badgeDiameter,
                ringThickness: widget.ringThickness,
              );
            },
          );
        }

        return _RestingPie(
          slices: _currentSlices,
          size: size,
          startOffset: _currentStartOffset,
          hotIndex: _hotIndex,
          animation: widget.animation,
          minIconSweep: minIconSweep,
          fullIconSweep: fullIconSweep,
          badgeDiameter: widget.badgeDiameter,
          ringThickness: widget.ringThickness,
          pressedGrowth: widget.pressedGrowth,
          pressGrowthAnimation: widget.pressGrowthAnimation,
          onTouch: _handleTouch,
        );
      },
    );
  }

  void _handleTouch(FlTouchEvent event, PieTouchResponse? response) {
    if (_isBusy) return;
    final slices = _currentSlices;
    final index = response?.touchedSection?.touchedSectionIndex;
    final valid = index != null && index >= 0 && index < slices.length;

    if (event is FlTapDownEvent || event is FlLongPressStart) {
      if (!valid) return;
      setState(() => _hotIndex = index);
      return;
    }

    if (event is FlTapUpEvent) {
      if (!valid) {
        setState(() => _hotIndex = null);
        return;
      }
      _expand(index);
      return;
    }

    if (event is FlTapCancelEvent || event is FlPanEndEvent || event is FlLongPressEnd) {
      setState(() => _hotIndex = null);
    }
  }

  void _expand(int index) {
    if (_isBusy) _settle();
    final slices = _currentSlices;
    if (index < 0 || index >= slices.length) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _drillIndex = index;
      _drillForward = true;
      _hotIndex = null;
    });
    _syncControllerPath();
    _expansion.forward(from: 0);
  }

  void _collapse() {
    if (_isBusy) _settle();
    if (_path.isEmpty) return;
    unawaited(HapticFeedback.selectionClick());
    final index = _path.removeLast();
    _offsetStack.removeLast();
    setState(() {
      _drillIndex = index;
      _drillForward = false;
      _hotIndex = null;
    });
    _syncControllerPath();
    _expansion.value = 1;
    _expansion.reverse();
  }

  void _reset() {
    unawaited(HapticFeedback.selectionClick());
    _expansion
      ..stop()
      ..value = 0;
    setState(() {
      _path.clear();
      _offsetStack
        ..clear()
        ..add(_rootStartOffset);
      _drillIndex = null;
      _drillForward = true;
      _hotIndex = null;
    });
    _syncControllerPath();
  }
}

/// One painted frame of a level transition (outgoing pie + optional children).
final class _ExpandFrame extends StatelessWidget {
  final List<ComminglePieSlice> slices;
  final double progress;
  final int selectedIndex;
  final double size;
  final double startOffset;
  final double minIconSweep;
  final double fullIconSweep;
  final double badgeDiameter;
  final double ringThickness;

  const _ExpandFrame({
    required this.slices,
    required this.progress,
    required this.selectedIndex,
    required this.size,
    required this.startOffset,
    required this.minIconSweep,
    required this.fullIconSweep,
    required this.badgeDiameter,
    required this.ringThickness,
  });

  @override
  Widget build(BuildContext context) {
    final selected = slices[selectedIndex];
    final t = progress.clamp(0.0, 1.0);
    final values = _expandedParentValues(slices, selectedIndex, t);
    final sum = values.fold<double>(0, (total, value) => total + value);
    if (sum <= 0) {
      return SizedBox.square(dimension: size);
    }
    final sweeps = [for (final value in values) value / sum * 2 * math.pi];
    final fixedMidpoint = _restingMidpoint(slices, selectedIndex, startOffset: startOffset);
    final offset = _offsetKeepingMidpoint(values, selectedIndex, fixedMidpoint);
    final siblingOpacity = 1.0 - t;
    final showChildren = selected.hasChildren;
    // With children: stay fully visible until halfway, then fade out under the
    // incoming overlay. Leaves stay opaque and become a closed ring.
    final selectedOpacity = showChildren ? (t <= 0.5 ? 1.0 : 2 * (1 - t)) : 1.0;

    final sectionsSpace = _sectionsSpaceDegrees * (1 - t);

    if (!showChildren && t >= 1) {
      return _ClosedRing(
        size: size,
        color: selected.color,
        midDegree: fixedMidpoint,
        ringThickness: ringThickness,
        badgeDiameter: badgeDiameter,
        badge: _badgeForSweep(
          context: context,
          section: selected,
          sweepRadians: 2 * math.pi,
          minIconSweep: minIconSweep,
          fullIconSweep: fullIconSweep,
        ),
      );
    }

    final parentPie = _buildRingPie(
      context: context,
      size: size,
      offset: offset,
      ringThickness: ringThickness,
      sectionsSpace: sectionsSpace,
      slices: [
        for (var i = 0; i < slices.length; i++)
          if (values[i] > 0)
            _RingSlice(
              section: slices[i],
              value: values[i],
              sweepRadians: sweeps[i],
              color: i == selectedIndex
                  ? slices[i].color.withValues(alpha: selectedOpacity)
                  : slices[i].color.withValues(alpha: siblingOpacity),
              badgeOpacity: i == selectedIndex ? selectedOpacity : siblingOpacity,
            ),
      ],
      minIconSweep: minIconSweep,
      fullIconSweep: fullIconSweep,
    );

    if (!showChildren) return parentPie;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (t < 1) parentPie,
          Opacity(
            opacity: t,
            child: _buildRingPie(
              context: context,
              size: size,
              offset: offset,
              ringThickness: ringThickness,
              sectionsSpace: selected.slices.length > 1 ? _sectionsSpaceDegrees : 0,
              slices: _childOverlaySlices(
                parentSlices: slices,
                selectedIndex: selectedIndex,
                parentValues: values,
                valueSum: sum,
              ),
              minIconSweep: minIconSweep,
              fullIconSweep: fullIconSweep,
            ),
          ),
        ],
      ),
    );
  }
}

final class _ClosedRing extends StatelessWidget {
  final double size;
  final Color color;
  final double midDegree;
  final double ringThickness;
  final double badgeDiameter;
  final Widget? badge;

  const _ClosedRing({
    required this.size,
    required this.color,
    required this.midDegree,
    required this.ringThickness,
    required this.badgeDiameter,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final hole = size / 2 - ringThickness;
    final midRadius = hole + ringThickness / 2;
    final midRadians = midDegree * math.pi / 180;
    final badgeOffset = Offset(
      size / 2 + midRadius * math.cos(midRadians),
      size / 2 + midRadius * math.sin(midRadians),
    );

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _ClosedRingPainter(
              color: color,
              holeRadius: hole,
              thickness: ringThickness,
            ),
          ),
          if (badge != null)
            Positioned(
              left: badgeOffset.dx - badgeDiameter / 2,
              top: badgeOffset.dy - badgeDiameter / 2,
              child: badge!,
            ),
        ],
      ),
    );
  }
}

final class _ClosedRingPainter extends CustomPainter {
  final Color color;
  final double holeRadius;
  final double thickness;

  const _ClosedRingPainter({
    required this.color,
    required this.holeRadius,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..isAntiAlias = true;
    canvas.drawCircle(center, holeRadius + thickness / 2, paint);
  }

  @override
  bool shouldRepaint(covariant _ClosedRingPainter oldDelegate) =>
      color != oldDelegate.color || holeRadius != oldDelegate.holeRadius || thickness != oldDelegate.thickness;
}

final class _RingSlice {
  final ComminglePieSlice? section;
  final double value;
  final double sweepRadians;
  final Color color;
  final double badgeOpacity;
  final bool showBadge;

  const _RingSlice({
    required this.section,
    required this.value,
    required this.sweepRadians,
    required this.color,
    this.badgeOpacity = 1,
    this.showBadge = true,
  });
}

Widget _buildRingPie({
  required BuildContext context,
  required double size,
  required double offset,
  required List<_RingSlice> slices,
  required double minIconSweep,
  required double fullIconSweep,
  required double ringThickness,
  double sectionsSpace = _sectionsSpaceDegrees,
}) {
  final hole = size / 2 - ringThickness;

  final chart = SizedBox.square(
    dimension: size,
    child: PieChart(
      duration: Duration.zero,
      PieChartData(
        startDegreeOffset: offset,
        sectionsSpace: sectionsSpace,
        centerSpaceRadius: hole,
        pieTouchData: PieTouchData(enabled: false),
        sections: [
          for (final slice in slices)
            PieChartSectionData(
              value: slice.value,
              color: slice.color,
              radius: ringThickness,
              showTitle: false,
              badgeWidget: slice.showBadge && slice.section != null
                  ? _badgeForSweep(
                      context: context,
                      section: slice.section!,
                      sweepRadians: slice.sweepRadians,
                      minIconSweep: minIconSweep,
                      fullIconSweep: fullIconSweep,
                      opacity: slice.badgeOpacity,
                    )
                  : null,
              badgePositionPercentageOffset: 0.5,
            ),
        ],
      ),
    ),
  );

  return chart;
}

List<_RingSlice> _childOverlaySlices({
  required List<ComminglePieSlice> parentSlices,
  required int selectedIndex,
  required List<double> parentValues,
  required double valueSum,
}) {
  final selected = parentSlices[selectedIndex];
  final selectedValue = parentValues[selectedIndex];
  final slices = <_RingSlice>[];

  for (var i = 0; i < selectedIndex; i++) {
    if (parentValues[i] <= 0) continue;
    slices.add(
      _RingSlice(
        section: null,
        value: parentValues[i],
        sweepRadians: parentValues[i] / valueSum * 2 * math.pi,
        color: Colors.transparent,
        showBadge: false,
      ),
    );
  }

  for (final child in selected.slices) {
    final value = selectedValue * child.value;
    slices.add(
      _RingSlice(
        section: child,
        value: value,
        sweepRadians: value / valueSum * 2 * math.pi,
        color: child.color,
      ),
    );
  }

  for (var i = selectedIndex + 1; i < parentSlices.length; i++) {
    if (parentValues[i] <= 0) continue;
    slices.add(
      _RingSlice(
        section: null,
        value: parentValues[i],
        sweepRadians: parentValues[i] / valueSum * 2 * math.pi,
        color: Colors.transparent,
        showBadge: false,
      ),
    );
  }

  return slices;
}

List<double> _expandedParentValues(
  List<ComminglePieSlice> slices,
  int selectedIndex,
  double t,
) {
  return [
    for (var i = 0; i < slices.length; i++) i == selectedIndex ? slices[i].value : _lerp(slices[i].value, 0, t),
  ];
}

final class _RestingPie extends StatelessWidget {
  final List<ComminglePieSlice> slices;
  final double size;
  final double startOffset;
  final int? hotIndex;
  final CommingleChartsAnimation animation;
  final double minIconSweep;
  final double fullIconSweep;
  final double badgeDiameter;
  final double ringThickness;
  final double pressedGrowth;
  final CommingleChartsAnimation? pressGrowthAnimation;
  final void Function(FlTouchEvent, PieTouchResponse?) onTouch;

  const _RestingPie({
    required this.slices,
    required this.size,
    required this.startOffset,
    required this.hotIndex,
    required this.animation,
    required this.minIconSweep,
    required this.fullIconSweep,
    required this.badgeDiameter,
    required this.ringThickness,
    required this.pressedGrowth,
    required this.pressGrowthAnimation,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return SizedBox.square(dimension: size);
    }

    final hole = size / 2 - ringThickness;
    final total = slices.fold<double>(0, (sum, section) => sum + section.value);
    final sweeps = [
      for (final section in slices) section.value / total * 2 * math.pi,
    ];
    final sectionsSpace = slices.length > 1 ? _sectionsSpaceDegrees : 0.0;

    // Single leaf section: closed ring avoids fl_chart's near-360 seam.
    if (slices.length == 1) {
      final section = slices.first;
      final mid = startOffset + 180;
      return _ClosedRing(
        size: size,
        color: section.color,
        midDegree: mid,
        ringThickness: ringThickness,
        badgeDiameter: badgeDiameter,
        badge: _badgeForSweep(
          context: context,
          section: section,
          sweepRadians: 2 * math.pi,
          minIconSweep: minIconSweep,
          fullIconSweep: fullIconSweep,
        ),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: PieChart(
        duration: pressGrowthAnimation?.duration ?? Duration.zero,
        curve: pressGrowthAnimation?.curve ?? animation.curve,
        PieChartData(
          startDegreeOffset: startOffset,
          sectionsSpace: sectionsSpace,
          centerSpaceRadius: hole,
          pieTouchData: PieTouchData(
            enabled: true,
            touchCallback: onTouch,
          ),
          sections: [
            for (var i = 0; i < slices.length; i++)
              PieChartSectionData(
                value: slices[i].value,
                color: slices[i].color,
                radius: hotIndex == i ? ringThickness + pressedGrowth : ringThickness,
                showTitle: false,
                badgeWidget: _badgeForSweep(
                  context: context,
                  section: slices[i],
                  sweepRadians: sweeps[i],
                  minIconSweep: minIconSweep,
                  fullIconSweep: fullIconSweep,
                ),
                badgePositionPercentageOffset: 0.5,
              ),
          ],
        ),
      ),
    );
  }
}

/// Sweep where a badge of [badgeDiameter] fits the ring’s mid-arc.
double awesomePieChartFullIconSweep({
  double size = 320,
  double badgeDiameter = awesomePieChartDefaultBadgeDiameter,
  double ringThickness = awesomePieChartDefaultRingThickness,
}) {
  final midRadius = size / 2 - ringThickness / 2;
  return 2 * math.asin((badgeDiameter / 2) / midRadius);
}

/// Sweep at which the badge is half size; below this it is omitted.
double awesomePieChartMinIconSweep({
  double size = 320,
  double badgeDiameter = awesomePieChartDefaultBadgeDiameter,
  double ringThickness = awesomePieChartDefaultRingThickness,
}) =>
    awesomePieChartFullIconSweep(
      size: size,
      badgeDiameter: badgeDiameter,
      ringThickness: ringThickness,
    ) /
    2;

Widget? _badgeForSweep({
  required BuildContext context,
  required ComminglePieSlice section,
  required double sweepRadians,
  required double minIconSweep,
  required double fullIconSweep,
  double opacity = 1.0,
}) {
  if (opacity <= 0 || sweepRadians < minIconSweep) return null;

  final built = section.iconBuilder(context);
  final Widget icon;
  if (sweepRadians >= fullIconSweep) {
    icon = built;
  } else {
    final t = (sweepRadians - minIconSweep) / (fullIconSweep - minIconSweep);
    icon = Transform.scale(
      scale: 0.5 + 0.5 * t.clamp(0.0, 1.0),
      child: built,
    );
  }

  if (opacity >= 1) return icon;
  return Opacity(opacity: opacity, child: icon);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _restingMidpoint(
  List<ComminglePieSlice> slices,
  int index, {
  double startOffset = _rootStartOffset,
}) {
  final total = slices.fold<double>(0, (sum, section) => sum + section.value);
  var valueBefore = 0.0;
  for (var i = 0; i < index; i++) {
    valueBefore += slices[i].value;
  }
  return startOffset + valueBefore / total * 360 + slices[index].value / total * 180;
}

double _offsetKeepingMidpoint(
  List<double> values,
  int selectedIndex,
  double fixedMidpoint,
) {
  final sum = values.fold<double>(0, (total, value) => total + value);
  var valueBefore = 0.0;
  for (var i = 0; i < selectedIndex; i++) {
    valueBefore += values[i];
  }
  return fixedMidpoint - valueBefore / sum * 360 - values[selectedIndex] / sum * 180;
}

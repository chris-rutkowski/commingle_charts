import 'package:flutter/animation.dart';

/// Optional animation config. Provide both [duration] and [curve] to animate;
/// pass the whole object as null to disable animation (instant change).
final class CommingleChartsAnimation {
  final Duration duration;
  final Curve curve;

  const CommingleChartsAnimation({
    required this.duration,
    required this.curve,
  });
}

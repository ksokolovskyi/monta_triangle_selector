// ignore_for_file: sort_constructors_first

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:monta_triangle_selector/triangle_selector_value.dart';

/// {@template triangle_model}
/// Represents a rounded equilateral triangle shape with various properties
/// and attributes.
///
/// Encapsulates the geometric properties of an rounded equilateral triangle,
/// including the positions of its vertices, the radius of the vertices, the
/// center point, the bounding rectangle, and the paths defining the shape of
/// the triangle.
///
/// Also provides methods to convert [TriangleSelectorValue] into position
/// inside the triangle and vice versa.
/// {@endtemplate}
class TriangleModel {
  /// {@macro triangle_model}
  TriangleModel._({
    required this.radius,
    required this.a,
    required this.aRounded,
    required this.b,
    required this.bRounded,
    required this.c,
    required this.cRounded,
    required this.center,
    required this.bounds,
    required this.path,
    required this.innerPath,
    required this.innerArea,
  });

  /// The vertex radius.
  final double radius;

  /// The top vertex.
  final Offset a;

  /// The rounded top vertex.
  final Offset aRounded;

  /// The bottom left vertex.
  final Offset b;

  /// The rounded bottom left vertex.
  final Offset bRounded;

  /// The bottom right vertex.
  final Offset c;

  /// The rounded bottom right vertex.
  final Offset cRounded;

  /// The center point of the triangle.
  final Offset center;

  /// The rectangle bounding the triangle.
  final Rect bounds;

  /// The path representing the rounded triangle shape formed by [a], [b] and
  /// [c] vertices and [radius].
  final Path path;

  /// The path of the sharp triangle shape formed by [aRounded], [bRounded] and
  /// [cRounded] vertices.
  final Path innerPath;

  /// The area of the sharp triangle shape formed by [aRounded], [bRounded] and
  /// [cRounded] vertices.
  final double innerArea;

  static final tan60 = math.tan(math.pi / 3);
  static final cos60 = math.cos(math.pi / 3);
  static final sin60 = math.sin(math.pi / 3);
  static final cos30 = math.cos(math.pi / 6);
  static final sin30 = math.sin(math.pi / 6);

  /// {@macro triangle_model}
  factory TriangleModel.fromRectAndRadius(Rect rect, double radius) {
    final side = rect.width;
    final height = side * math.sqrt(3) / 2;
    final diameter = radius * 2;

    // The calculations are highly inspired by this Stack Overflow answer:
    // https://stackoverflow.com/a/78055140.
    final S = radius / cos60;
    final L = radius * tan60;
    final h = L * sin60;
    final base = 2 * L * cos60;
    final arcHeight = radius / 2;

    final triangleBounds = Rect.fromCenter(
      center: rect.center.translate(0, -arcHeight),
      width: side,
      height: height,
    );

    final a = Offset(triangleBounds.left + side / 2, triangleBounds.top);
    final b = Offset(triangleBounds.left, triangleBounds.top + height);
    final c = Offset(triangleBounds.right, triangleBounds.top + height);

    final arcRectA = Rect.fromCenter(
      center: Offset(a.dx, a.dy + S),
      width: diameter,
      height: diameter,
    );

    final arcRectB = Rect.fromCenter(
      center: Offset(
        b.dx + S * cos30,
        b.dy - S * sin30,
      ),
      width: diameter,
      height: diameter,
    );

    final arcRectC = Rect.fromCenter(
      center: Offset(
        c.dx - S * cos30,
        c.dy - S * sin30,
      ),
      width: diameter,
      height: diameter,
    );

    final path = Path()
      ..moveTo(a.dx - base / 2, a.dy + h)
      ..arcTo(arcRectA, math.pi + math.pi / 6, 2 * math.pi / 3, false)
      ..lineTo(
        c.dx - L * cos60,
        c.dy - L * sin60,
      )
      ..arcTo(arcRectC, -math.pi / 6, 2 * math.pi / 3, false)
      ..lineTo(b.dx + L, b.dy)
      ..arcTo(arcRectB, math.pi / 3 + math.pi / 6, 2 * math.pi / 3, false)
      ..close();

    final distanceFromVertexToArc = S - radius;
    final dx = distanceFromVertexToArc * cos30;
    final dy = distanceFromVertexToArc * sin30;

    final aRounded = Offset(
      triangleBounds.center.dx,
      triangleBounds.top + distanceFromVertexToArc,
    );
    final bRounded = Offset(
      triangleBounds.left + dx,
      triangleBounds.bottom - dy,
    );
    final cRounded = Offset(
      triangleBounds.right - dx,
      triangleBounds.bottom - dy,
    );
    final center = Offset(
      triangleBounds.center.dx,
      triangleBounds.top + triangleBounds.height * 2 / 3,
    );

    final innerPath = Path()
      ..moveTo(aRounded.dx, aRounded.dy)
      ..lineTo(bRounded.dx, bRounded.dy)
      ..lineTo(cRounded.dx, cRounded.dy)
      ..close();

    final innerArea = _getTriangleArea(aRounded, bRounded, cRounded);

    return TriangleModel._(
      radius: radius,
      a: a,
      aRounded: aRounded,
      b: b,
      bRounded: bRounded,
      c: c,
      cRounded: cRounded,
      center: center,
      bounds: triangleBounds,
      path: path,
      innerPath: innerPath,
      innerArea: innerArea,
    );
  }

  /// Clamps the given point to be inside the triangle formed by the vertices
  /// [aRounded], [bRounded], and [cRounded].
  ///
  /// If the point is outside the triangle, it is projected onto the nearest
  /// edge of the triangle.
  Offset clampPointInsideTriangle(Offset point) {
    if (innerPath.contains(point)) {
      return point;
    }

    return _findClosestPointOnInnerPath(point);
  }

  Offset _findClosestPointOnInnerPath(Offset point) {
    var minDistance = double.infinity;
    var closestPoint = a;

    final vertices = [aRounded, bRounded, cRounded, aRounded];

    for (var i = 0; i < vertices.length - 1; i++) {
      final closestPointOnLine = _closestPointOnLine(
        vertices[i],
        vertices[i + 1],
        point,
      );
      final distance = (closestPointOnLine - point).distanceSquared;

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = closestPointOnLine;
      }
    }

    return closestPoint;
  }

  Offset _closestPointOnLine(Offset a, Offset b, Offset p) {
    // Calculate vector components.
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;

    // Calculate the squared length of the line segment.
    final segmentLengthSquared = dx * dx + dy * dy;

    // Calculate the parameterized position along the line segment.
    var t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / segmentLengthSquared;

    // Clamp t to the range [0, 1].
    t = t.clamp(0.0, 1.0);

    // Calculate the closest point.
    return Offset(
      a.dx + t * dx,
      a.dy + t * dy,
    );
  }

  /// Converts a percentage values from the [value] to a point inside the
  /// triangle.
  Offset pointFromValue(TriangleSelectorValue value) {
    final dx = value.aValue * aRounded.dx +
        value.bValue * bRounded.dx +
        value.cValue * cRounded.dx;
    final dy = value.aValue * aRounded.dy +
        value.bValue * bRounded.dy +
        value.cValue * cRounded.dy;

    final point = Offset(dx, dy);

    return point;
  }

  /// Converts a point inside the triangle into the percentage values.
  TriangleSelectorValue valueFromPoint(Offset point) {
    final aArea = _getTriangleArea(point, bRounded, cRounded);
    final bArea = _getTriangleArea(point, aRounded, cRounded);
    final cArea = _getTriangleArea(point, aRounded, bRounded);

    return TriangleSelectorValue(
      aValue: aArea / innerArea,
      bValue: bArea / innerArea,
      cValue: cArea / innerArea,
    );
  }

  static double _getTriangleArea(Offset a, Offset b, Offset c) {
    return 0.5 *
        (a.dx * (b.dy - c.dy) + b.dx * (c.dy - a.dy) + c.dx * (a.dy - b.dy))
            .abs();
  }
}

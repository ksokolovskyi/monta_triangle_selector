import 'package:equatable/equatable.dart';

/// {@template triangle_selector_value}
/// Represents the distribution of percentage values among three vertices of a
/// triangle selector.
/// {@endtemplate}
class TriangleSelectorValue extends Equatable {
  /// {@macro triangle_selector_value}
  const TriangleSelectorValue({
    required this.aValue,
    required this.bValue,
    required this.cValue,
  });

  /// The percentage value allocated to the top vertex of the triangle.
  ///
  /// The value have to be withing range [0, 1].
  final double aValue;

  /// The percentage value allocated to the bottom left vertex of the triangle.
  ///
  /// The value have to be withing range [0, 1].
  final double bValue;

  /// The percentage value allocated to the bottom right vertex of the triangle.
  ///
  /// The value have to be withing range [0, 1].
  final double cValue;

  @override
  List<Object?> get props => [aValue, bValue, cValue];
}

import 'package:flutter/material.dart';

/// A custom clipper that creates a curved bottom edge.
/// Used for the mobile auth hero header to create visual interest.
class CurvedBottomClipper extends CustomClipper<Path> {
  final double curveHeight;

  CurvedBottomClipper({this.curveHeight = 30});

  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.lineTo(0, 0);

    // Go down the left side to where the curve starts
    path.lineTo(0, size.height - curveHeight);

    // Create a smooth curve across the bottom
    path.quadraticBezierTo(
      size.width / 2, // Control point x (center)
      size.height + curveHeight * 0.5, // Control point y (below bottom)
      size.width, // End point x (right side)
      size.height - curveHeight, // End point y
    );

    // Go up the right side
    path.lineTo(size.width, 0);

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CurvedBottomClipper oldClipper) {
    return curveHeight != oldClipper.curveHeight;
  }
}

/// A wave-style clipper for more dynamic visual effect.
class WaveBottomClipper extends CustomClipper<Path> {
  final double waveHeight;

  WaveBottomClipper({this.waveHeight = 20});

  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, 0);
    path.lineTo(0, size.height - waveHeight);

    // First curve (left to center)
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - waveHeight,
    );

    // Second curve (center to right)
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - waveHeight * 2,
      size.width,
      size.height - waveHeight,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant WaveBottomClipper oldClipper) {
    return waveHeight != oldClipper.waveHeight;
  }
}

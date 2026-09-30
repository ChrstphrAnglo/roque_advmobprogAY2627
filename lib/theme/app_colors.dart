import 'package:flutter/material.dart';

/// The five palette colours, plus the neutrals needed for legible text and dark mode.
class AppColors {
  AppColors._();

  static const indigo = Color(0xFF4D52B4);
  static const blue = Color(0xFF4E9CE8);
  static const aqua = Color(0xFF70D6C5);
  static const sage = Color(0xFFCAE5BC);
  static const mist = Color(0xFFE1EDD4);

  /// Deep indigo used for text on light surfaces.
  static const ink = Color(0xFF1B1D45);

  /// Dark-mode background and its raised surfaces.
  static const night = Color(0xFF10122E);
  static const nightSurface = Color(0xFF171A40);
  static const nightRaised = Color(0xFF262A66);

  /// Sent bubbles: indigo easing toward blue, kept dark enough for white text.
  static final sentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, Color.lerp(indigo, blue, 0.45)!],
  );

  /// Chat canvas: the palette's own top-to-bottom wash, softened to stay readable.
  static LinearGradient chatCanvas(Brightness brightness) {
    return brightness == Brightness.light
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [mist, Color.lerp(mist, aqua, 0.45)!],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [night, Color.lerp(night, indigo, 0.4)!],
          );
  }

  /// Avatar background / foreground pairs, each with readable contrast.
  static const avatarPairs = <(Color, Color)>[
    (indigo, Colors.white),
    (blue, ink),
    (aqua, ink),
    (sage, ink),
  ];
}

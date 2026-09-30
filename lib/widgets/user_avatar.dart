import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'custom_text.dart';

/// Initial-in-a-circle avatar. The colour is picked from the palette by [seed]
/// so the same person always looks the same; [heroTag] lets it fly between screens.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.seed,
    this.radius = 22,
    this.heroTag,
  });

  final String name;
  final String seed;
  final double radius;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final pairs = AppColors.avatarPairs;
    final (background, foreground) =
        pairs[seed.codeUnits.fold<int>(0, (a, b) => a + b) % pairs.length];

    // Material keeps the text styled correctly while the Hero is mid-flight.
    Widget avatar = Material(
      type: MaterialType.transparency,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: background,
        child: CustomText(
          text: name.isNotEmpty ? name[0].toUpperCase() : '?',
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
    if (heroTag != null) avatar = Hero(tag: heroTag!, child: avatar);
    return avatar;
  }
}

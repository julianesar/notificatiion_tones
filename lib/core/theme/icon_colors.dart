import 'package:flutter/material.dart';

class AppIconColors {
  const AppIconColors._();

  static const Color favoriteActive = Color(0xFFE57373);

  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

  static Color disabled(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);

  static Color onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
}

extension AppIconColorsExtension on BuildContext {
  Color get iconPrimary => AppIconColors.primary(this);
  Color get iconSecondary => AppIconColors.secondary(this);
  Color get iconDisabled => AppIconColors.disabled(this);
  Color get iconOnPrimary => AppIconColors.onPrimary(this);
  Color get iconFavoriteActive => AppIconColors.favoriteActive;
}
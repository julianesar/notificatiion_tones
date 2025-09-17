import 'package:flutter/material.dart';

class AppIconColors {
  const AppIconColors._();

  static const Color favoriteActive = Color(0xFFDC5151);

  static const Color appRed = Color(0xFFDC5151);

  static const Color trashRed = Color(0xFFEF5350);

  static Color iconBlack(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

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
  Color get iconAppRed => AppIconColors.appRed;
  Color get iconTrashRed => AppIconColors.trashRed;
  Color get iconBlack => AppIconColors.iconBlack(this);
}
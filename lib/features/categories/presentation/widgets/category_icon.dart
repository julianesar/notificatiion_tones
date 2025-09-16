import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryIcon extends StatelessWidget {
  final String? iconUrl;
  final String title;
  final double size;
  final Color? color;

  const CategoryIcon({
    super.key,
    this.iconUrl,
    required this.title,
    this.size = 40,
    this.color,
  });

  IconData _getFallbackIcon() {
    final titleLower = title.toLowerCase();

    if (titleLower.contains('notificacion') ||
        titleLower.contains('notification')) {
      return Icons.notifications;
    } else if (titleLower.contains('alarm') ||
        titleLower.contains('despertar')) {
      return Icons.alarm;
    } else if (titleLower.contains('llamada') ||
        titleLower.contains('call') ||
        titleLower.contains('ring')) {
      return Icons.phone;
    } else if (titleLower.contains('mensaje') ||
        titleLower.contains('sms') ||
        titleLower.contains('text')) {
      return Icons.message;
    } else if (titleLower.contains('social') || titleLower.contains('red')) {
      return Icons.people;
    } else if (titleLower.contains('clasic') ||
        titleLower.contains('classic') ||
        titleLower.contains('vintage')) {
      return Icons.library_music;
    } else if (titleLower.contains('email') ||
        titleLower.contains('mail') ||
        titleLower.contains('correo')) {
      return Icons.email;
    } else if (titleLower.contains('game') || titleLower.contains('juego')) {
      return Icons.videogame_asset;
    } else if (titleLower.contains('nature') ||
        titleLower.contains('natural')) {
      return Icons.nature;
    } else if (titleLower.contains('electronic') ||
        titleLower.contains('digital')) {
      return Icons.computer;
    } else {
      return Icons.music_note;
    }
  }

  bool _isSvgUrl(String url) {
    return url.toLowerCase().endsWith('.svg');
  }


  Widget _buildFallbackIcon(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    return Icon(
      _getFallbackIcon(),
      size: size,
      color: iconColor,
    );
  }


  @override
  Widget build(BuildContext context) {
    // Si no hay iconUrl, usa directamente el fallback
    if (iconUrl == null || iconUrl!.isEmpty) {
      return _buildFallbackIcon(context);
    }

    final iconColor = color ?? Theme.of(context).colorScheme.primary;

    // Para SVGs, usa SvgPicture con caché automático
    if (_isSvgUrl(iconUrl!)) {
      return SvgPicture.network(
        iconUrl!,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildFallbackIcon(context),
      );
    }

    // Para imágenes no-SVG (PNG, JPG, etc.), usa CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: iconUrl!,
      width: size,
      height: size,
      errorWidget: (context, url, error) => _buildFallbackIcon(context),
      imageBuilder: (context, imageProvider) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

}
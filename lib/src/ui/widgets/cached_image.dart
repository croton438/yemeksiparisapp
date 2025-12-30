import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedImg extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;

  const CachedImg({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (context, _) => _PlaceholderBox(width: width, height: height),
      errorWidget: (context, _, __) => _ErrorBox(width: width, height: height),
    );

    if (borderRadius == null) return image;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final double? width;
  final double? height;
  const _PlaceholderBox({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surface.withAlpha((0.35 * 255).round());

    return Container(
      width: width,
      height: height,
      color: base,
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final double? width;
  final double? height;
  const _ErrorBox({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surface.withAlpha((0.35 * 255).round());

    return Container(
      width: width,
      height: height,
      color: base,
      child: const Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}

import 'package:flutter/material.dart';

class NetImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const NetImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        color: Colors.white.withValues(alpha: 0.10),
        child: (u == null || u.isEmpty)
            ? const Icon(Icons.image_outlined, color: Colors.white)
            : Image.network(
                u,
                fit: fit,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

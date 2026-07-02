import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/chat_api_service.dart';
import '../widgets/app_shell.dart';

class FeedCard extends StatelessWidget {
  final Map item;
  final bool canRequest;
  final bool requestLoading;
  final VoidCallback onRequest;

  const FeedCard({
    super.key,
    required this.item,
    required this.canRequest,
    required this.requestLoading,
    required this.onRequest,
  });

  String _date10(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  static const String _fallback =
      'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=60';

  String _safeUrl(dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return '';
    return s;
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'meyve':
      case 'sebze':
        return const Color(0xFF16A34A);
      case 'ekmek':
      case 'unlu':
        return const Color(0xFFD97706);
      case 'süt':
      case 'süt ürünleri':
        return const Color(0xFF0284C7);
      case 'et':
      case 'tavuk':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  Widget _netImage(String url) {
    final u = url.isNotEmpty ? url : _fallback;
    return Image.network(
      u,
      fit: BoxFit.cover,
      cacheWidth: 1200,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Image.network(
        _fallback,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.black38),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final title = (item['name'] ?? 'Ürün').toString();
    final desc = (item['description'] ?? '').toString();
    final category = (item['category'] ?? '').toString();
    final expiry = _date10(item['expiry_date'] ?? item['expiryDate']);

    final donorId = (item['donor_id'] as num?)?.toInt() ?? 0;
    final donorName =
        (item['donor_username'] ?? item['donor_full_name'] ?? 'Kullanıcı')
            .toString();
    final donorAvatar = _safeUrl(item['donor_avatar_url']);
    final address =
        (item['address'] ?? item['fridge_address'] ?? '').toString();
    final imageUrl = _safeUrl(item['image_url'] ?? item['imageUrl']);

    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final titleColor = isDark ? Colors.white : AppShell.kInk;
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.5);

    void openProfile() {
      if (donorId <= 0) return;
      context.push('/user/$donorId', extra: {
        'displayName': donorName,
        'avatarUrl': donorAvatar,
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Donor header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: donorId > 0 ? openProfile : null,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : cs.primary.withValues(alpha: 0.12),
                      backgroundImage: donorAvatar.isNotEmpty
                          ? NetworkImage(donorAvatar)
                          : null,
                      onBackgroundImageError:
                          donorAvatar.isNotEmpty ? (_, __) {} : null,
                      child: donorAvatar.isEmpty
                          ? Text(
                              donorName.isNotEmpty
                                  ? donorName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : cs.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: donorId > 0 ? openProfile : null,
                          child: Text(
                            donorName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (address.isNotEmpty)
                          Text(
                            address,
                            style: TextStyle(fontSize: 11, color: subColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _categoryColor(category).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              _categoryColor(category).withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: _categoryColor(category),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Image ────────────────────────────────────────────────────────
            AspectRatio(aspectRatio: 16 / 9, child: _netImage(imageUrl)),

            // ── Content ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: titleColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: TextStyle(fontSize: 13, color: subColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (expiry.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: subColor),
                        const SizedBox(width: 4),
                        Text(
                          'Son tüketim: $expiry',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  // ── Action buttons ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 17),
                          label: const Text('Mesaj'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white : AppShell.kInk,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.15),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          onPressed: (!canRequest || donorId <= 0)
                              ? null
                              : () async {
                                  try {
                                    final thread =
                                        await ChatApiService().openDm(donorId);
                                    if (!context.mounted) return;
                                    context.push('/chat/${thread.id}', extra: {
                                      'partnerName':
                                          thread.otherUserFullName ?? donorName,
                                      'partnerId': donorId,
                                      'partnerAvatarUrl': donorAvatar.isNotEmpty
                                          ? donorAvatar
                                          : null,
                                    });
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Mesaj açılamadı: $e')),
                                    );
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: requestLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  canRequest
                                      ? Icons.volunteer_activism_rounded
                                      : Icons.lock_outline_rounded,
                                  size: 17,
                                ),
                          label: Text(
                            canRequest
                                ? (requestLoading
                                    ? 'Gönderiliyor…'
                                    : 'İstek Gönder')
                                : 'Sadece İhtiyaç Sahibi',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: canRequest
                                ? AppShell.kGreen
                                : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed:
                              (canRequest && !requestLoading) ? onRequest : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

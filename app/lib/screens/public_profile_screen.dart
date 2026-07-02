import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/services/item_service.dart';
import 'package:foodbridge/services/donation_api_service.dart';
import 'package:foodbridge/widgets/feed_card.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final int userId;
  final String? displayName;
  final String? avatarUrl;
  final bool? canRequest;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.canRequest,
  });

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  final _itemService = ItemService();
  final _donationApi = DonationApiService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _user;
  List<dynamic> _items = [];

  final Set<int> _requesting = {};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  bool _isNeedyRole(String role) => role.toUpperCase() == 'NEEDY';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bundle = await _itemService.getPublicProfileBundle(
        userId: widget.userId,
      );

      final uRaw = bundle['user'];
      final u = (uRaw is Map)
          ? Map<String, dynamic>.from(uRaw)
          : <String, dynamic>{};

      final listRaw = bundle['items'];
      final list = (listRaw is List) ? listRaw : <dynamic>[];

      if (!mounted) return;
      setState(() {
        _user = u;
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Widget _card({required Widget child}) {
    if (_isDark) {
      return GlassBox(child: child);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).user;
    final myRole = (me?.role ?? '').trim();
    final canRequest = widget.canRequest ?? _isNeedyRole(myRole);

    final u = _user ?? {};
    final fullName = (u['full_name'] ?? u['fullName'] ?? '').toString().trim();
    final username = (u['username'] ?? '').toString().trim();
    final bio = (u['bio'] ?? '').toString().trim();
    final avatar = (u['avatar_url'] ?? u['avatarUrl'] ?? '').toString().trim();

    // ✅ AppBar ile Header aynı kaynaktan beslensin:
    final resolvedName = (fullName.isNotEmpty)
        ? fullName
        : (widget.displayName?.trim().isNotEmpty == true
              ? widget.displayName!.trim()
              : (username.isNotEmpty ? '@$username' : 'Kullanıcı'));

    final resolvedAvatar = avatar.isNotEmpty
        ? avatar
        : (widget.avatarUrl ?? '');

    final title = resolvedName.isNotEmpty ? resolvedName : 'Profil';

    final errStyle = TextStyle(
      color: _isDark ? Colors.white : _ink,
      fontWeight: FontWeight.w800,
    );

    return AppShell(
      appBar: buildGlassAppBar(
        context: context,
        title: title,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: errStyle,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                children: [
                  _PublicHeader(
                    displayName: resolvedName,
                    username: username,
                    bio: bio,
                    avatarUrl: resolvedAvatar,
                    isDark: _isDark,
                    ink: _ink,
                    brand: _brand,
                  ),
                  const SizedBox(height: 14),
                  if (_items.isEmpty)
                    _card(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : _brand.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.inbox_outlined,
                              color: _isDark ? Colors.white : _ink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Henüz paylaşım yok.",
                              style: TextStyle(
                                color: _isDark ? Colors.white : _ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.map((raw) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      final itemId = (item['id'] as num?)?.toInt() ?? 0;
                      final sending = _requesting.contains(itemId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FeedCard(
                          item: item,
                          canRequest: canRequest,
                          requestLoading: sending,
                          onRequest: () async {
                            if (!canRequest || sending || itemId <= 0) return;

                            setState(() => _requesting.add(itemId));
                            try {
                              await _donationApi.requestDonation(
                                itemId: itemId,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('İstek gönderildi'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              final msg = e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              );
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(msg)));
                            } finally {
                              if (mounted) {
                                setState(() => _requesting.remove(itemId));
                              }
                            }
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _PublicHeader extends StatelessWidget {
  final String displayName;
  final String username;
  final String bio;
  final String avatarUrl;

  final bool isDark;
  final Color ink;
  final Color brand;

  const _PublicHeader({
    required this.displayName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.isDark,
    required this.ink,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final nameText = displayName.trim().isNotEmpty
        ? displayName.trim()
        : 'Kullanıcı';
    final userText = username.isNotEmpty ? '@$username' : '';
    final av = avatarUrl.trim();

    final titleColor = isDark ? Colors.white : ink;
    final subColor = isDark ? Colors.white70 : ink.withValues(alpha: 0.75);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.20)
              : brand.withValues(alpha: 0.12),
          backgroundImage: av.isNotEmpty ? NetworkImage(av) : null,
          onBackgroundImageError: av.isNotEmpty ? (_, __) {} : null,
          child: av.isEmpty
              ? Icon(Icons.person, size: 30, color: isDark ? Colors.white : ink)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nameText,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: titleColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (userText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  userText,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: subColor,
                  ),
                ),
              ],
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: TextStyle(
                    fontSize: 13,
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

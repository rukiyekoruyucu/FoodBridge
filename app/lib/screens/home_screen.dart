import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:foodbridge/services/item_service.dart';
import 'package:foodbridge/services/donation_api_service.dart';
import 'package:foodbridge/services/location_service.dart';
import 'package:foodbridge/services/user_service.dart';

import 'package:foodbridge/widgets/feed_card.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;
  final bool embedded;

  const HomeScreen({super.key, required this.userRole, this.embedded = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationService = LocationService();
  final _donationApi = DonationApiService();

  bool loading = true;
  List<dynamic> items = [];
  String? error;

  String mode = "latest";
  double radiusKm = 10;

  List<dynamic> topDonors = [];
  bool loadingTop = true;

  final Set<int> _requestingItemIds = {};

  @override
  void initState() {
    super.initState();
    _loadTopDonors();
    _loadFeed();
  }

  Future<void> _loadTopDonors() async {
    try {
      final data = await UserService().getLeaderboard(limit: 10);
      if (!mounted) return;
      setState(() {
        topDonors = data;
        loadingTop = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingTop = false);
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (mode == "latest") {
        final data = await ItemService().getLatestFeed(limit: 20);
        if (!mounted) return;
        setState(() {
          items = data;
          loading = false;
        });
        return;
      }

      final pos = await _locationService.getCurrentLocation();
      final data = await ItemService().getNearbyFeed(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusKm: radiusKm,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        items = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      if (mode == "nearby") {
        setState(() {
          mode = "latest";
          loading = false;
          error = "Konum alınamadı. En yeniler gösteriliyor.\n${e.toString()}";
        });
        await _loadFeed();
        return;
      }

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _searchFeed(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      await _loadFeed();
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (mode == "latest") {
        final data = await ItemService().getLatestFeed(limit: 20, q: query);
        if (!mounted) return;
        setState(() {
          items = data;
          loading = false;
        });
        return;
      }

      final pos = await _locationService.getCurrentLocation();
      final data = await ItemService().getNearbyFeed(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusKm: radiusKm,
        limit: 20,
        q: query,
      );

      if (!mounted) return;
      setState(() {
        items = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadTopDonors(), _loadFeed()]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canRequest = widget.userRole == 'NEEDY';

    final ink = AppShell.kInk;
    final brand = AppShell.kGreen;

    return AppShell(
      withBackground: !widget.embedded,
      safeArea: false,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.transparent : brand,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 12,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset('assets/foodbridge_logo.png', width: 44, height: 44),
            const SizedBox(width: 10),
            const Text(
              'FoodBridge',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Mesajlar',
            onPressed: () => context.push('/chat'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Bildirimler',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: _HomeSearchBar(
              onSearch: _searchFeed,
              isDark: isDark,
              ink: ink,
              brand: brand,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // HEADER (light: yeşil, scroll ile gider)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.transparent : brand,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: "Bu Ayın En Hayırseverleri",
                        subtitle: "Küçük bir yardım, büyük bir fark yaratır",
                        isDark: isDark,
                        forceWhite: !isDark,
                      ),
                      const SizedBox(height: 10),

                      if (loadingTop)
                        const SizedBox(
                          height: 92,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (topDonors.isEmpty)
                        _surfaceBox(
                          context,
                          height: 92,
                          child: Center(
                            child: Text(
                              "Henüz liderlik verisi yok",
                              style: TextStyle(
                                color: isDark ? Colors.white : ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 112,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: topDonors.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final d = topDonors[i] as Map;
                              return _TopDonorCardReal(
                                d: d,
                                rank: i + 1,
                                isDark: isDark,
                                ink: ink,
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 16),

                      _surfaceBox(
                        context,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _ModeChip(
                                    selected: mode == "latest",
                                    icon: Icons.schedule,
                                    label: "En Yeniler",
                                    onTap: () {
                                      if (mode == "latest") return;
                                      setState(() => mode = "latest");
                                      _loadFeed();
                                    },
                                    isDark: isDark,
                                    ink: ink,
                                    brand: brand,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ModeChip(
                                    selected: mode == "nearby",
                                    icon: Icons.near_me,
                                    label: "Yakınımda",
                                    onTap: () {
                                      if (mode == "nearby") return;
                                      setState(() => mode = "nearby");
                                      _loadFeed();
                                    },
                                    isDark: isDark,
                                    ink: ink,
                                    brand: brand,
                                  ),
                                ),
                              ],
                            ),
                            if (mode == "nearby") ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    "Yarıçap: ${radiusKm.toStringAsFixed(0)} km",
                                    style: TextStyle(
                                      color: isDark ? Colors.white : ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: radiusKm,
                                min: 1,
                                max: 50,
                                divisions: 49,
                                onChanged: (v) => setState(() => radiusKm = v),
                                onChangeEnd: (_) => _loadFeed(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // FEED (light: beyaz)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (loading) ...[
                      const SizedBox(height: 10),
                      _buildShimmerList(isDark),
                    ] else if (error != null) ...[
                      _EmptyState(
                        title: "Bir şeyler ters gitti",
                        subtitle: error!,
                        buttonText: "Yenile",
                        onPressed: _loadFeed,
                        isDark: isDark,
                        ink: ink,
                      ),
                    ] else if (items.isEmpty) ...[
                      _EmptyState(
                        title: mode == "nearby"
                            ? "Yakınında bağış bulunamadı"
                            : "Henüz bağış yok",
                        subtitle: mode == "nearby"
                            ? "Yarıçapı artırmayı dene."
                            : "İlk bağışlar gelince burada görünecek.",
                        buttonText: "Yenile",
                        onPressed: _loadFeed,
                        isDark: isDark,
                        ink: ink,
                      ),
                    ] else ...[
                      _SectionHeader(
                        title: "Bağış Akışı",
                        subtitle: mode == "latest"
                            ? "Yeni eklenen bağışlar"
                            : "Yakınındaki bağışlar",
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      ...items.map((raw) {
                        final item = raw as Map;
                        final itemId = (item['id'] as num).toInt();
                        final isSending = _requestingItemIds.contains(itemId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FeedCard(
                            item: item,
                            canRequest: canRequest,
                            requestLoading: isSending,
                            onRequest: () async {
                              if (!canRequest) return;
                              if (_requestingItemIds.contains(itemId)) return;

                              setState(() => _requestingItemIds.add(itemId));
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
                                  setState(
                                    () => _requestingItemIds.remove(itemId),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(6, (_) => const _ShimmerFeedCard()),
      ),
    );
  }
}

/// Skeleton card for shimmer loading effect
class _ShimmerFeedCard extends StatelessWidget {
  const _ShimmerFeedCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 90,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Text placeholders
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(height: 14, color: Colors.white, width: double.infinity),
                    Container(height: 12, color: Colors.white, width: 180),
                    Container(height: 12, color: Colors.white, width: 120),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// theme-aware card container
Widget _surfaceBox(
  BuildContext context, {
  double? height,
  EdgeInsetsGeometry padding = const EdgeInsets.all(10),
  required Widget child,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: isDark
          ? null
          : [
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final bool forceWhite;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.forceWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = (isDark || forceWhite) ? Colors.white : AppShell.kInk;
    final subColor = (isDark || forceWhite)
        ? Colors.white.withValues(alpha: 0.85)
        : AppShell.kInk.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: subColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  final bool isDark;
  final Color ink;
  final Color brand;

  const _ModeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.ink,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? (selected
              ? Colors.white.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.12))
        : (selected
              ? brand.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.03));

    final fg = isDark ? Colors.white : (selected ? brand : ink);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  final bool isDark;
  final Color ink;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    required this.isDark,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return _surfaceBox(
      context,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.88)
                  : ink.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchBar extends StatefulWidget {
  final Future<void> Function(String q) onSearch;
  final bool isDark;
  final Color ink;
  final Color brand;

  const _HomeSearchBar({
    required this.onSearch,
    required this.isDark,
    required this.ink,
    required this.brand,
  });

  @override
  State<_HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<_HomeSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white;
    final border = widget.isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.06);

    final fg = widget.isDark ? Colors.white : widget.ink;
    final hint = widget.isDark
        ? Colors.white.withValues(alpha: 0.8)
        : widget.ink.withValues(alpha: 0.55);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: widget.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(Icons.search, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
              textInputAction: TextInputAction.search,
              onSubmitted: (q) => widget.onSearch(q.trim()),
              decoration: InputDecoration(
                hintText: "Ara (ürün, kategori...)",
                hintStyle: TextStyle(color: hint, fontWeight: FontWeight.w700),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: widget.isDark ? Colors.white : widget.brand,
            ),
            onPressed: () => widget.onSearch(_ctrl.text.trim()),
          ),
        ],
      ),
    );
  }
}

// --------- PREMIUM LEADERBOARD (ring + badge) ---------

class _TopDonorCardReal extends StatelessWidget {
  final Map d;
  final int rank;
  final bool isDark;
  final Color ink;

  const _TopDonorCardReal({
    required this.d,
    required this.rank,
    required this.isDark,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final username = (d['username'] ?? '').toString().trim();
    final points = (d['kindness_points'] ?? 0).toString();
    final avatar = (d['avatar_url'] ?? '').toString().trim();

    final top3 = rank <= 3;
    final palette = _RankPalette.forRank(rank);

    final textColor = isDark ? Colors.white : ink;
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : ink.withValues(alpha: 0.75);

    return Container(
      width: 198,
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: top3
              ? palette.border.withValues(alpha: isDark ? 0.72 : 0.55)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.06)),
          width: top3 ? 1.2 : 1.0,
        ),
        boxShadow: isDark
            ? (top3
                  ? [
                      BoxShadow(
                        color: palette.glow.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        children: [
          _RankedAvatar(
            avatarUrl: avatar,
            rank: rank,
            palette: palette,
            isDark: isDark,
            ink: ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        username.isEmpty ? "kullanıcı" : username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    if (top3)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          palette.icon,
                          size: 18,
                          color: palette.iconColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$points puan",
                  style: TextStyle(
                    color: subColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedAvatar extends StatelessWidget {
  final String avatarUrl;
  final int rank;
  final _RankPalette palette;
  final bool isDark;
  final Color ink;

  const _RankedAvatar({
    required this.avatarUrl,
    required this.rank,
    required this.palette,
    required this.isDark,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final top3 = rank <= 3;

    const double outer = 50;
    const double inner = 40;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (top3)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.glow.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        Container(
          width: outer,
          height: outer,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: top3 ? palette.ringGradient : null,
            color: top3
                ? null
                : (isDark
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.black.withValues(alpha: 0.03)),
            border: Border.all(
              color: top3
                  ? palette.border.withValues(alpha: 0.55)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.08)),
              width: top3 ? 1.2 : 1.0,
            ),
          ),
          child: Center(
            child: Container(
              width: inner,
              height: inner,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.03),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
          ),
        ),
        if (top3)
          Positioned(
            right: -6,
            top: -8,
            child: _RankBadge(rank: rank, palette: palette),
          ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.03),
      child: Icon(Icons.person, color: isDark ? Colors.white : ink),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final _RankPalette palette;
  const _RankBadge({required this.rank, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: palette.badgeGradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(palette.icon, size: 14.5, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            "$rank",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankPalette {
  final Gradient ringGradient;
  final Gradient badgeGradient;
  final Color border;
  final Color glow;
  final IconData icon;
  final Color iconColor;

  const _RankPalette({
    required this.ringGradient,
    required this.badgeGradient,
    required this.border,
    required this.glow,
    required this.icon,
    required this.iconColor,
  });

  static _RankPalette forRank(int rank) {
    if (rank == 1) {
      return const _RankPalette(
        ringGradient: SweepGradient(
          colors: [
            Color(0xFF6E4F00),
            Color(0xFFFFE9A6),
            Color(0xFFFFC94A),
            Color(0xFFFFF2C2),
            Color(0xFFB17800),
            Color(0xFF6E4F00),
          ],
          stops: [0.00, 0.18, 0.42, 0.62, 0.82, 1.00],
        ),
        badgeGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC83D), Color(0xFFFFA800), Color(0xFFB87400)],
        ),
        border: Color(0xFFFFD76A),
        glow: Color(0xFFFFC83D),
        icon: Icons.emoji_events,
        iconColor: Color(0xFFFFD76A),
      );
    }

    if (rank == 2) {
      return const _RankPalette(
        ringGradient: SweepGradient(
          colors: [
            Color(0xFF2F3A45),
            Color(0xFFE9EEF5),
            Color(0xFFB9C6D6),
            Color(0xFFF7FAFF),
            Color(0xFF6E7B8A),
            Color(0xFF2F3A45),
          ],
          stops: [0.00, 0.18, 0.40, 0.62, 0.82, 1.00],
        ),
        badgeGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB9C6D6), Color(0xFF7F8A98), Color(0xFF3E4A56)],
        ),
        border: Color(0xFFDCE6F2),
        glow: Color(0xFFB9C6D6),
        icon: Icons.workspace_premium,
        iconColor: Color(0xFFDCE6F2),
      );
    }

    return const _RankPalette(
      ringGradient: SweepGradient(
        colors: [
          Color(0xFF4C1F10),
          Color(0xFFFFD0B8),
          Color(0xFFC87843),
          Color(0xFFFFE3D4),
          Color(0xFF8E4E2A),
          Color(0xFF4C1F10),
        ],
        stops: [0.00, 0.18, 0.42, 0.62, 0.82, 1.00],
      ),
      badgeGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCC7A45), Color(0xFF9B4F2B), Color(0xFF5B2715)],
      ),
      border: Color(0xFFFFD0B8),
      glow: Color(0xFFCC7A45),
      icon: Icons.military_tech,
      iconColor: Color(0xFFFFD0B8),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/models/donation.dart';
import 'package:foodbridge/models/private_fridge.dart';

import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/providers/chat_threads_notifier.dart';

import 'package:foodbridge/services/chat_api_service.dart';
import 'package:foodbridge/services/donation_api_service.dart';
import 'package:foodbridge/services/item_service.dart';
import 'package:foodbridge/services/private_fridge_api_service.dart';

import 'package:foodbridge/widgets/add_donation_sheet.dart';
import 'package:foodbridge/widgets/app_shell.dart';

import 'chat_screen.dart';
import 'donation_requests_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _donationApi = DonationApiService();
  final _itemService = ItemService();
  final _privateApi = PrivateFridgeApiService();
  final _chatApi = ChatApiService();

  bool _loading = true;
  String? _error;

  List<_Notif> _items = const [];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  bool _isDonorRole(String role) {
    final r = role.trim().toUpperCase();
    return r == 'PERSONAL' || r == 'CORPORATE';
  }

  String _s(dynamic v) => (v ?? '').toString();
  int _i(dynamic v) => v is num ? v.toInt() : (int.tryParse(_s(v)) ?? 0);

  int _safeTs(dynamic raw) {
    if (raw == null) return DateTime.now().millisecondsSinceEpoch;
    try {
      return DateTime.parse(raw.toString()).toLocal().millisecondsSinceEpoch;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  int? _daysLeft(DateTime? expiry) {
    if (expiry == null) return null;
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(expiry.year, expiry.month, expiry.day);
    return d1.difference(d0).inDays;
  }

  String _timeAgo(int ts) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (now - ts).abs() ~/ 1000;
    if (diff < 60) return '${diff}s';
    final m = diff ~/ 60;
    if (m < 60) return '${m}dk';
    final h = m ~/ 60;
    if (h < 24) return '${h}sa';
    final d = h ~/ 24;
    return '${d}g';
  }

  // ------------------ THEME-AWARE CARD ------------------
  Widget _card({required Widget child, VoidCallback? onTap}) {
    if (_isDark) {
      return GlassBox(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: child,
        ),
      );
    }

    return Container(
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
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: child,
      ),
    );
  }

  Widget _leadingIconBox(IconData icon, {_NotifKind? kind}) {
    if (_isDark) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white),
      );
    }

    Color bg = _brand.withValues(alpha: 0.12);
    Color fg = _ink;

    // küçük ton farkı (daha okunur ve “anlamlı”)
    if (kind == _NotifKind.expiry) bg = Colors.orange.withValues(alpha: 0.16);
    if (kind == _NotifKind.accepted) bg = _brand.withValues(alpha: 0.16);
    if (kind == _NotifKind.request) bg = _brand.withValues(alpha: 0.12);
    if (kind == _NotifKind.chat) bg = Colors.blue.withValues(alpha: 0.12);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Icon(icon, color: fg),
    );
  }

  // ------------------ MAIN REFRESH ------------------
  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Chat refresh
      ref.read(chatThreadsProvider.notifier).refresh();

      final me = ref.read(authProvider).user;
      final myId = me?.id ?? -1;
      final myRole = (me?.role ?? '').toString();

      final notifs = <_Notif>[];

      // 1) New message notifs (threads)
      notifs.addAll(_buildChatNotifs());

      // 2) Donation-related notifs
      notifs.addAll(await _buildDonationNotifs(myId: myId, myRole: myRole));

      // 3) Expiry notifs (private fridges)
      notifs.addAll(await _buildExpiryNotifs(myRole: myRole));

      // sort newest first
      notifs.sort((a, b) => b.ts.compareTo(a.ts));

      if (!mounted) return;
      setState(() {
        _items = notifs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ----------------------- CHAT -----------------------
  List<_Notif> _buildChatNotifs() {
    final st = ref.read(chatThreadsProvider);
    final out = <_Notif>[];

    for (final t in st.threads) {
      final last = (t.lastMessage ?? '').trim();
      if (last.isEmpty) continue;

      final partner = (t.otherUserFullName ?? 'Sohbet').toString();
      final ts = _safeTs(t.lastMessageAt);

      out.add(
        _Notif(
          kind: _NotifKind.chat,
          icon: Icons.chat_bubble_outline,
          title: 'Yeni mesaj',
          subtitle: '$partner: $last',
          ts: ts,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(roomId: t.id, partnerName: partner),
              ),
            );
          },
        ),
      );

      if (out.length >= 12) break;
    }

    return out;
  }

  // ----------------------- DONATION -----------------------
  Future<List<_Notif>> _buildDonationNotifs({
    required int myId,
    required String myRole,
  }) async {
    final out = <_Notif>[];
    final isDonor = _isDonorRole(myRole);

    final myDonations = await _donationApi.listMyDonations();

    for (final d in myDonations) {
      final st = d.status.toUpperCase();

      if (!isDonor && d.recipientId == myId && st == 'ACCEPTED') {
        final itemName = (d.itemName ?? 'Bağış').toString();
        out.add(
          _Notif(
            kind: _NotifKind.accepted,
            icon: Icons.check_circle_outline,
            title: 'Bağış kabul edildi',
            subtitle: '$itemName • Git al ve mesajlaş',
            ts: _safeTs(d.acceptedAt ?? d.createdAt),
            onTap: () async {
              try {
                final room = await _chatApi.openDm(d.donorId);
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      roomId: room.id,
                      partnerName: room.otherUserFullName ?? 'Bağışçı',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                final msg = e.toString().replaceFirst('Exception: ', '');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
          ),
        );
      }
    }

    if (isDonor) {
      final myItems = await _itemService.getMyPublicItems(limit: 40);
      int produced = 0;

      for (final raw in myItems) {
        if (produced >= 10) break;

        final m = Map<String, dynamic>.from(raw as Map);
        final itemId = _i(m['id']);
        if (itemId <= 0) continue;

        final reqs = await _donationApi.listItemRequests(itemId: itemId);
        final pending = reqs
            .where((x) => x.status.toUpperCase() == 'PENDING')
            .toList();
        if (pending.isEmpty) continue;

        final itemName = (m['name'] ?? pending.first.itemName ?? 'Ürün')
            .toString();

        pending.sort(
          (a, b) => _safeTs(b.createdAt).compareTo(_safeTs(a.createdAt)),
        );
        final newest = pending.first;
        final who = (newest.requesterFullName ?? 'Bir kullanıcı').toString();

        out.add(
          _Notif(
            kind: _NotifKind.request,
            icon: Icons.notifications_active_outlined,
            title: 'Bağışına istek geldi (${pending.length})',
            subtitle: '$who → $itemName',
            ts: _safeTs(newest.createdAt),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DonationRequestsScreen(itemId: itemId),
                ),
              );
            },
          ),
        );

        produced++;
      }
    }

    return out;
  }

  // ----------------------- EXPIRY -----------------------
  Future<List<_Notif>> _buildExpiryNotifs({required String myRole}) async {
    final out = <_Notif>[];

    final List<PrivateFridge> fridges = await _privateApi
        .listMyPrivateFridges();

    for (final f in fridges) {
      final exp = await _privateApi.listExpiringItemsInPrivateFridge(
        f.id.toString(),
        daysBefore: 3,
      );

      for (final it in exp) {
        final expiry = _parseDate(it['expiryDate'] ?? it['expiry_date']);
        final left = _daysLeft(expiry);

        final name = (it['name'] ?? 'Ürün').toString();
        final ts =
            expiry?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;

        out.add(
          _Notif(
            kind: _NotifKind.expiry,
            icon: Icons.warning_amber_rounded,
            title: (left != null && left < 0) ? 'SKT geçti' : 'SKT yaklaşıyor',
            subtitle:
                '$name • ${(left == null) ? "tarih yok" : (left < 0 ? "geçti" : "$left gün")} • ${f.name}',
            ts: ts,
            onTap: () => _openExpiryActions(
              fridgeId: f.id.toString(),
              fridgeName: f.name.toString(),
              myRole: myRole,
              item: it,
            ),
          ),
        );

        if (out.length >= 12) return out;
      }
    }

    return out;
  }

  Future<void> _openExpiryActions({
    required String fridgeId,
    required String fridgeName,
    required String myRole,
    required Map<String, dynamic> item,
  }) async {
    final itemId = _i(item['id']);
    final name = (item['name'] ?? 'Ürün').toString();

    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Text('Buzdolabı: $fridgeName\nNe yapmak istersin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'close'),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Sil'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'donate'),
            child: const Text('Bağışla'),
          ),
        ],
      ),
    );

    if (action == 'delete') {
      try {
        await _privateApi.deletePrivateItem(fridgeId, itemId);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ürün silindi.')));
        await _refresh();
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      return;
    }

    if (action == 'donate') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddDonationSheet(
          userRole: myRole,
          initialName: (item['name'] ?? '').toString(),
          initialDescription: (item['description'] ?? item['desc'] ?? '')
              .toString(),
          initialQuantity: item['quantity'] is num
              ? (item['quantity'] as num).toInt()
              : int.tryParse((item['quantity'] ?? '').toString()),
          initialExpiry: _parseDate(item['expiryDate'] ?? item['expiry_date']),
          initialCategory: (item['category'] ?? '').toString(),
          initialImageUrl: (item['imageUrl'] ?? item['image_url'] ?? '')
              .toString(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatThreadsProvider);

    final titleColor = _isDark ? Colors.white : _ink;
    final subColor = _isDark ? Colors.white70 : _ink.withValues(alpha: 0.70);

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : (_error != null)
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isDark ? Colors.white : _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              children: [
                _card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _leadingIconBox(Icons.notifications, kind: null),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bildirimler',
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                chatState.error != null
                                    ? 'Chat: hata var'
                                    : 'Mesaj • İstek • SKT',
                                style: TextStyle(
                                  color: subColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (_items.isEmpty)
                  _card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          _leadingIconBox(Icons.inbox_outlined, kind: null),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Şu an bildirim yok.',
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._items.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _card(
                        onTap: n.onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _leadingIconBox(n.icon, kind: n.kind),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: TextStyle(
                                              color: titleColor,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _timeAgo(n.ts),
                                          style: TextStyle(
                                            color: subColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.subtitle,
                                      style: TextStyle(
                                        color: subColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right, color: subColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );

    return AppShell(
      appBar: buildGlassAppBar(
        context: context,
        title: 'Bildirimler',
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: body,
    );
  }
}

enum _NotifKind { request, accepted, chat, expiry }

class _Notif {
  final _NotifKind kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final int ts;
  final VoidCallback onTap;

  const _Notif({
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ts,
    required this.onTap,
  });
}

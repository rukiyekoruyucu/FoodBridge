import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/models/donation.dart';
import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/services/donation_api_service.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class ItemRequestsCompactScreen extends ConsumerStatefulWidget {
  final int itemId;
  final String itemTitle;

  const ItemRequestsCompactScreen({
    super.key,
    required this.itemId,
    required this.itemTitle,
  });

  @override
  ConsumerState<ItemRequestsCompactScreen> createState() =>
      _ItemRequestsCompactScreenState();
}

class _ItemRequestsCompactScreenState
    extends ConsumerState<ItemRequestsCompactScreen> {
  final _donationApi = DonationApiService();

  bool _loading = true;
  bool _mutating = false;
  String? _error;

  List<Donation> _requests = [];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final reqs = await _donationApi.listItemRequests(itemId: widget.itemId);
      if (!mounted) return;
      setState(() {
        _requests = reqs;
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

  Future<void> _accept(int donationId) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await _donationApi.acceptRequest(donationId: donationId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İstek kabul edildi.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _reject(int donationId) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await _donationApi.rejectRequest(donationId: donationId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İstek reddedildi.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _confirmPickup(int donationId) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await _donationApi.confirmPickup(donationId: donationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teslim edildi olarak işaretlendi.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Widget _card({required Widget child}) {
    if (_isDark) {
      return GlassBox(padding: const EdgeInsets.all(12), child: child);
    }
    return Container(
      padding: const EdgeInsets.all(12),
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
    final myId = me?.id ?? -1;

    return AppShell(
      appBar: buildGlassAppBar(
        context: context,
        title: 'İstekler • ${widget.itemTitle}',
        actions: [
          IconButton(
            onPressed: (_loading || _mutating) ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isDark ? Colors.white : _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : _requests.isEmpty
          ? Center(
              child: Text(
                'Henüz istek yok.',
                style: TextStyle(
                  color: _isDark ? Colors.white : _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = _requests[i];
                final status = d.status.toUpperCase();

                final name = (d.requesterFullName ?? 'Kullanıcı').trim().isEmpty
                    ? 'Kullanıcı'
                    : d.requesterFullName!.trim();

                final avatar = (d.requesterAvatarUrl ?? '').trim();

                final isPending = status == 'PENDING';
                final isAccepted = status == 'ACCEPTED';
                final isCompleted = status == 'COMPLETED';

                final nameColor = _isDark ? Colors.white : _ink;

                return _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.black.withValues(alpha: 0.03),
                            backgroundImage: avatar.isNotEmpty
                                ? NetworkImage(avatar)
                                : null,
                            onBackgroundImageError: avatar.trim().isNotEmpty
                                ? (_, __) {}
                                : null,
                            child: avatar.isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: _isDark ? Colors.white : _ink,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: nameColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _StatusPill(
                            status: status,
                            isDark: _isDark,
                            ink: _ink,
                            brand: _brand,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.person_outline),
                            label: const Text('Profili Gör'),
                            style: !_isDark
                                ? OutlinedButton.styleFrom(
                                    foregroundColor: _brand,
                                    side: BorderSide(
                                      color: _brand.withValues(alpha: 0.55),
                                    ),
                                  )
                                : null,
                          ),
                          const Spacer(),

                          if (isPending) ...[
                            OutlinedButton(
                              onPressed: _mutating ? null : () => _reject(d.id),
                              style: !_isDark
                                  ? OutlinedButton.styleFrom(
                                      foregroundColor: _ink,
                                      side: BorderSide(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    )
                                  : null,
                              child: const Text('Reddet'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _mutating ? null : () => _accept(d.id),
                              style: !_isDark
                                  ? FilledButton.styleFrom(
                                      backgroundColor: _brand,
                                      foregroundColor: Colors.white,
                                    )
                                  : null,
                              child: const Text('Kabul Et'),
                            ),
                          ] else if (isAccepted) ...[
                            FilledButton.icon(
                              onPressed: _mutating
                                  ? null
                                  : () => _confirmPickup(d.id),
                              icon: const Icon(Icons.verified),
                              style: !_isDark
                                  ? FilledButton.styleFrom(
                                      backgroundColor: _brand,
                                      foregroundColor: Colors.white,
                                    )
                                  : null,
                              label: Text(
                                myId == d.donorId
                                    ? 'Teslim Ettim'
                                    : 'Teslim Aldım',
                              ),
                            ),
                          ] else if (isCompleted) ...[
                            Text(
                              'Bağış tamamlandı',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _isDark ? Colors.white : _ink,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Durum: —',
                              style: TextStyle(
                                color: _isDark
                                    ? Colors.white70
                                    : _ink.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool isDark;
  final Color ink;
  final Color brand;

  const _StatusPill({
    required this.status,
    required this.isDark,
    required this.ink,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (isDark) {
      bg = Colors.black.withValues(alpha: 0.06);
      fg = Colors.white;
    } else {
      fg = ink;
      bg = Colors.black.withValues(alpha: 0.03);

      if (status == 'PENDING') bg = Colors.orange.withValues(alpha: 0.16);
      if (status == 'ACCEPTED') bg = brand.withValues(alpha: 0.14);
      if (status == 'COMPLETED') bg = Colors.grey.withValues(alpha: 0.18);
      if (status == 'REJECTED') bg = Colors.red.withValues(alpha: 0.12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

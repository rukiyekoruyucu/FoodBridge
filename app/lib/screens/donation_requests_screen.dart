import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:foodbridge/models/donation.dart';
import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/services/donation_api_service.dart';
import 'package:foodbridge/services/item_service.dart';

import 'package:foodbridge/services/chat_api_service.dart';
import 'package:foodbridge/widgets/app_shell.dart';



String date10(dynamic v) {
  if (v == null) return '';
  final s = v.toString();
  return s.length >= 10 ? s.substring(0, 10) : s;
}

class DonationRequestsScreen extends ConsumerStatefulWidget {
  final int itemId;
  const DonationRequestsScreen({super.key, required this.itemId});

  @override
  ConsumerState<DonationRequestsScreen> createState() =>
      _DonationRequestsScreenState();
}

class _DonationRequestsScreenState
    extends ConsumerState<DonationRequestsScreen> {
  final _donationApi = DonationApiService();
  final _itemService = ItemService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _item;
  List<Donation> _requests = [];

  bool _mutating = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool _isDonorRole(String role) {
    final r = role.trim().toUpperCase();
    return r == 'PERSONAL' || r == 'CORPORATE';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = await _itemService.getItemDetail(id: widget.itemId);
      final reqs = await _donationApi.listItemRequests(itemId: widget.itemId);

      if (!mounted) return;
      setState(() {
        _item = item;
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

  Future<void> _editItem() async {
    final item = _item;
    if (item == null) return;

    final id = (item['id'] as num?)?.toInt();
    if (id == null || id <= 0) return;

    final nameCtrl = TextEditingController(
      text: (item['name'] ?? '').toString(),
    );
    final descCtrl = TextEditingController(
      text: (item['description'] ?? '').toString(),
    );
    final categoryCtrl = TextEditingController(
      text: (item['category'] ?? '').toString(),
    );
    final qtyCtrl = TextEditingController(
      text: (item['quantity'] ?? '').toString(),
    );
    final addressCtrl = TextEditingController(
      text: (item['address'] ?? item['fridge_address'] ?? '').toString(),
    );

    DateTime? expiry;
    final rawExpiry = (item['expiry_date'] ?? item['expiryDate'])?.toString();
    if (rawExpiry != null && rawExpiry.isNotEmpty) {
      expiry = DateTime.tryParse(rawExpiry);
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: StatefulBuilder(
              builder: (ctx, setModal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Bağışı Düzenle',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ürün adı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama (opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kategori (opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Adet (opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adres (opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: expiry ?? now,
                                firstDate: DateTime(now.year - 1),
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null)
                                setModal(() => expiry = picked);
                            },
                            icon: const Icon(Icons.date_range_outlined),
                            label: Text(
                              expiry == null
                                  ? 'Son tüketim tarihi'
                                  : 'Son tüketim: ${date10(expiry)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Kaydet'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (ok != true) return;

    try {
      final q = int.tryParse(qtyCtrl.text.trim());
      await _itemService.updateMyItem(
        id: id,
        name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        quantity: q,
        expiryDate: expiry,
        address: addressCtrl.text.trim(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bağış güncellendi.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).user;
    final role = (me?.role ?? '').trim();
    final isDonor = _isDonorRole(role);
    final myId = me?.id ?? -1;

    return AppShell(
      appBar: buildGlassAppBar(
        context: context,
        title: 'İstekler',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Bağışı Düzenle',
            onPressed: (_loading || _item == null || _mutating)
                ? null
                : _editItem,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_loading || _mutating) ? null : _load,
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
                  style: TextStyle(
                    color: _isDark ? Colors.white : _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
              children: [
                if (_item != null)
                  _ItemHeaderCard(item: _item!, ink: _ink, brand: _brand),
                const SizedBox(height: 12),
                if (!isDonor)
                  _InfoBox(
                    text:
                        'Bu ekran bağışçı için tasarlandı. İstekleri sadece bağışın sahibi onaylayabilir/reddedebilir.',
                    isDark: _isDark,
                    ink: _ink,
                    brand: _brand,
                  ),
                if (_requests.isEmpty)
                  _InfoBox(
                    text: 'Henüz istek yok.',
                    isDark: _isDark,
                    ink: _ink,
                    brand: _brand,
                  )
                else
                  ..._requests.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RequestCard(
                        donation: d,
                        myUserId: myId,
                        canModerate: isDonor && !_mutating,
                        isDark: _isDark,
                        ink: _ink,
                        brand: _brand,
                        onAccept: () => _accept(d.id),
                        onReject: () => _reject(d.id),
                        onOpenProfile: () {
                          context.push('/user/${d.recipientId}', extra: {
                            'displayName': d.requesterFullName,
                            'avatarUrl': d.requesterAvatarUrl,
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ItemHeaderCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color ink;
  final Color brand;

  const _ItemHeaderCard({
    required this.item,
    required this.ink,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final title = (item['name'] ?? 'Ürün').toString();
    final desc = (item['description'] ?? '').toString();
    final category = (item['category'] ?? '').toString();
    final expiry = date10(item['expiry_date'] ?? item['expiryDate']);
    final img = (item['image_url'] ?? item['imageUrl'] ?? '').toString();
    final addr = (item['address'] ?? item['fridge_address'] ?? '').toString();

    const fallback =
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=60';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                img.isNotEmpty ? img : fallback,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.network(fallback, fit: BoxFit.cover),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: DefaultTextStyle(
              style: TextStyle(color: ink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: ink,
                          ),
                        ),
                      ),
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (addr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      addr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(desc, style: TextStyle(fontSize: 13, color: ink)),
                  ],
                  if (expiry.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Son tüketim: $expiry',
                      style: TextStyle(
                        fontSize: 12,
                        color: ink.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final Donation donation;
  final int myUserId;
  final bool canModerate;
  final bool isDark;
  final Color ink;
  final Color brand;

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onOpenProfile;

  const _RequestCard({
    required this.donation,
    required this.myUserId,
    required this.canModerate,
    required this.isDark,
    required this.ink,
    required this.brand,
    required this.onAccept,
    required this.onReject,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatApi = ChatApiService();

    final status = donation.status.toUpperCase();

    final requesterName =
        (donation.requesterFullName ?? 'Kullanıcı').trim().isEmpty
        ? 'Kullanıcı'
        : donation.requesterFullName!.trim();

    final requesterAvatar = (donation.requesterAvatarUrl ?? '').trim();
    final isAccepted = status == 'ACCEPTED';
    final canOpenChat = isAccepted && myUserId == donation.recipientId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle(
          style: TextStyle(color: ink),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onOpenProfile,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: brand.withValues(alpha: 0.12),
                        backgroundImage: requesterAvatar.isNotEmpty
                            ? NetworkImage(requesterAvatar)
                            : null,
                        onBackgroundImageError:
                            requesterAvatar.trim().isNotEmpty
                            ? (_, __) {}
                            : null,
                        child: requesterAvatar.isEmpty
                            ? Icon(Icons.person, color: ink)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          requesterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                      ),
                      _StatusPill(status: status, ink: ink, brand: brand),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Mesaj'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brand,
                        side: BorderSide(color: brand.withValues(alpha: 0.55)),
                      ),
                      onPressed: canOpenChat
                          ? () async {
                              try {
                                final room = await chatApi.openDm(
                                  donation.donorId,
                                );
                                if (!context.mounted) return;
                                context.push('/chat/${room.id}', extra: {
                                  'partnerName': room.otherUserFullName ?? 'Bağışçı',
                                  'partnerId': donation.donorId,
                                });
                              } catch (e) {
                                if (!context.mounted) return;
                                final msg = e.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (canModerate && status == 'PENDING') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close),
                        label: const Text('Reddet'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ink,
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check),
                        label: const Text('Kabul Et'),
                        style: FilledButton.styleFrom(
                          backgroundColor: brand,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.lock_outline),
                        label: Text(isAccepted ? 'Kabul Edildi' : 'Bekleniyor'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final Color ink;
  final Color brand;

  const _StatusPill({
    required this.status,
    required this.ink,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.black.withValues(alpha: 0.03);
    if (status == 'PENDING') bg = Colors.orange.withValues(alpha: 0.16);
    if (status == 'ACCEPTED') bg = brand.withValues(alpha: 0.14);
    if (status == 'COMPLETED') bg = Colors.grey.withValues(alpha: 0.18);
    if (status == 'REJECTED') bg = Colors.red.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color ink;
  final Color brand;

  const _InfoBox({
    required this.text,
    required this.isDark,
    required this.ink,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    // Light: hafif yeşil tint
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : brand.withValues(alpha: 0.10);
    final bd = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : brand.withValues(alpha: 0.18);
    final fg = isDark ? Colors.white : ink;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bd),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

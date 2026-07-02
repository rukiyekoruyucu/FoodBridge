import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodbridge/services/upload_service.dart';
import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/services/item_service.dart';
import 'package:foodbridge/services/donation_api_service.dart';
import 'package:foodbridge/services/user_service.dart';
import 'package:foodbridge/models/donation.dart';
import 'package:foodbridge/widgets/app_shell.dart';
import 'package:flutter/foundation.dart';
import 'donation_requests_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _itemService = ItemService();
  final _donationApi = DonationApiService();
  final _userService = UserService();
  final UploadService _upload = createUploadService();
  final _picker = ImagePicker();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _myPublicItems = [];
  List<Donation> _myDonations = [];

  late final TabController _tabCtrl;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool _isDonorRole(String role) {
    final r = role.toUpperCase();
    return r == 'PERSONAL' || r == 'CORPORATE';
  }

  // ✅ önemli: item status'u önce oku
  String _statusOf(Map<String, dynamic> e) {
    final raw = e['item_status'] ?? e['itemStatus'] ?? e['status'] ?? '';
    return raw.toString().trim().toUpperCase();
  }

  // ✅ UI'da Türkçe status
  String _statusTr(String rawUpper) {
    final s = rawUpper.trim().toUpperCase();
    switch (s) {
      case 'AVAILABLE':
        return 'Uygun';
      case 'RESERVED':
        return 'Ayrıldı';
      case 'EXPIRED':
        return 'Süresi Doldu';
      case 'REMOVED':
        return 'Kaldırıldı';
      default:
        return s.isEmpty ? '—' : s;
    }
  }

  int _myId() => ref.read(authProvider).user?.id ?? -1;

  String _date10(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  String _roleText(String role) {
    switch (role.toUpperCase()) {
      case 'NEEDY':
        return 'İhtiyaç Sahibi';
      case 'CORPORATE':
        return 'Kurumsal Bağışçı';
      case 'PERSONAL':
      default:
        return 'Bireysel Bağışçı';
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final me = ref.read(authProvider).user;
      final role = (me?.role ?? '').trim();
      final isDonor = _isDonorRole(role);

      final futures = <Future<void>>[];

      futures.add(_donationApi.listMyDonations().then((v) => _myDonations = v));

      if (isDonor) {
        futures.add(
          _itemService.getMyPublicItems(limit: 200).then((v) {
            _myPublicItems = v
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

            _myPublicItems.sort((a, b) {
              final ad = DateTime.tryParse((a['created_at'] ?? '').toString());
              final bd = DateTime.tryParse((b['created_at'] ?? '').toString());
              if (ad == null && bd == null) return 0;
              if (ad == null) return 1;
              if (bd == null) return -1;
              return bd.compareTo(ad);
            });
          }),
        );
      } else {
        _myPublicItems = [];
      }

      await Future.wait(futures);

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ---------- UI HELPERS (theme aware) ----------
  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _isDark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: _isDark
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

  // ✅ Home’daki gibi: Image.network + errorBuilder ile kesin gösterim
  Widget _avatarLikeHome(String url, {double radius = 34}) {
    final u = url.trim();

    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: Colors.black.withValues(alpha: 0.03),
        child: u.isEmpty
            ? Icon(Icons.person, color: _ink, size: radius)
            : Image.network(
                u,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.person, color: _ink, size: radius),
              ),
      ),
    );
  }

  Widget _pill(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _isDark
            ? Colors.white.withValues(alpha: 0.14)
            : _brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.25)
              : _brand.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: _isDark ? Colors.white : _ink,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _statusPill(String rawStatusUpper) {
    final raw = rawStatusUpper.trim().toUpperCase();
    final label = _statusTr(raw);

    Color bg;
    Color fg;

    if (_isDark) {
      bg = Colors.white.withValues(alpha: 0.18);
      fg = Colors.white;
    } else {
      bg = _brand.withValues(alpha: 0.12);
      fg = _ink;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.25)
              : _brand.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  Widget _statusChip(String rawStatusUpper) {
    final raw = rawStatusUpper.trim().toUpperCase();
    final label = _statusTr(raw);

    Color bg;
    Color fg;

    if (_isDark) {
      bg = Colors.black.withValues(alpha: 0.06);
      fg = Colors.white;
      if (raw == 'AVAILABLE') bg = Colors.green.withValues(alpha: 0.12);
      if (raw == 'RESERVED') bg = Colors.orange.withValues(alpha: 0.14);
      if (raw == 'EXPIRED') bg = Colors.red.withValues(alpha: 0.12);
      if (raw == 'REMOVED') bg = Colors.grey.withValues(alpha: 0.14);
    } else {
      fg = _ink;
      bg = Colors.black.withValues(alpha: 0.03);
      if (raw == 'AVAILABLE') bg = _brand.withValues(alpha: 0.14);
      if (raw == 'RESERVED') bg = Colors.orange.withValues(alpha: 0.16);
      if (raw == 'EXPIRED') bg = Colors.red.withValues(alpha: 0.12);
      if (raw == 'REMOVED') bg = Colors.grey.withValues(alpha: 0.18);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  // ---------- ACTIONS ----------
  Future<void> _openEditProfileSheet() async {
    final u = ref.read(authProvider).user;
    if (u == null) return;

    final fullNameCtrl = TextEditingController(text: (u.fullName ?? '').trim());
    final usernameCtrl = TextEditingController(text: (u.username ?? '').trim());
    final avatarCtrl = TextEditingController(text: (u.avatarUrl ?? '').trim());
    final bioCtrl = TextEditingController(text: (u.bio ?? '').trim());

    bool saving = false;
    bool uploadingAvatar = false;

    Future<void> pickAndUploadAvatar(
      void Function(void Function()) setModal,
      BuildContext ctx,
    ) async {
      if (kIsWeb) {
        if (!ctx.mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text("Web'de fotoğraf yükleme kapalı. Android'de dene."),
          ),
        );
        return;
      }

      try {
        final x = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 800,
        );
        if (x == null) return;

        setModal(() => uploadingAvatar = true);

        final url = await _upload.uploadImageFromPath(
          x.path,
          folder: 'avatars',
        );

        setModal(() {
          uploadingAvatar = false;
          avatarCtrl.text = url;
        });
      } catch (e) {
        setModal(() => uploadingAvatar = false);
        if (!ctx.mounted) return;
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text('Avatar yüklenemedi: $e')));
      }
    }

    InputDecoration _editDec(BuildContext ctx, String label) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF7FDF9),
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.80)
              : _ink.withValues(alpha: 0.85),
          fontWeight: FontWeight.w800,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _brand, width: 1.6),
        ),
      );
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1D2A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Profili Düzenle',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: isDark ? Colors.white : _ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(ctx, false),
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.white : _ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: fullNameCtrl,
                      cursorColor: _brand,
                      style: TextStyle(
                        color: isDark ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: _editDec(ctx, 'Ad Soyad'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameCtrl,
                      cursorColor: _brand,
                      style: TextStyle(
                        color: isDark ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: _editDec(
                        ctx,
                        'Kullanıcı adı (benzersiz olmalı)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      cursorColor: _brand,
                      minLines: 2,
                      maxLines: 4,
                      style: TextStyle(
                        color: isDark ? Colors.white : _ink,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _editDec(ctx, 'Bio'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: avatarCtrl,
                      cursorColor: _brand,
                      style: TextStyle(
                        color: isDark ? Colors.white : _ink,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _editDec(
                        ctx,
                        'Profil Fotoğrafı URL (opsiyonel)',
                      ),
                      onChanged: (_) => setModal(() {}),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (saving || uploadingAvatar)
                            ? null
                            : () => pickAndUploadAvatar(setModal, ctx),
                        icon: uploadingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.photo_library_outlined, color: _brand),
                        label: Text(
                          uploadingAvatar
                              ? 'Yükleniyor...'
                              : 'Avatar seç & yükle',
                          style: TextStyle(
                            color: _brand,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _brand.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (avatarCtrl.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Image.network(
                                avatarCtrl.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.black12,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'URL geçerliyse fotoğraf güncellenir. Boş bırakırsan zorunlu değil.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                setModal(() => saving = true);
                                Navigator.pop(ctx, true);
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                              ),
                        label: Text(
                          saving ? 'Kaydediliyor...' : 'Kaydet',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (ok != true) return;

    try {
      await _userService.updateMe(
        fullName: fullNameCtrl.text.trim().isEmpty
            ? null
            : fullNameCtrl.text.trim(),
        username: usernameCtrl.text.trim().isEmpty
            ? null
            : usernameCtrl.text.trim(),
        avatarUrl: avatarCtrl.text.trim().isEmpty
            ? null
            : avatarCtrl.text.trim(),
        bio: bioCtrl.text.trim(),
      );

      await ref.read(authProvider.notifier).refreshMe();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil güncellendi.')));
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---------- CARDS ----------
  Widget _donationHistoryCard(Donation donation) {
    final d = donation.toJson();

    final id = (d['id'] as num?)?.toInt() ?? 0;
    final status = (d['status'] ?? '').toString().toUpperCase();
    final type = (d['type'] ?? '').toString().toUpperCase();

    final donorId = (d['donor_id'] as num?)?.toInt() ?? 0;
    final recipientId = (d['recipient_id'] as num?)?.toInt() ?? 0;

    final itemName = (d['item_name'] ?? 'Ürün').toString();
    final itemDesc = (d['item_description'] ?? '').toString();
    final itemImg = (d['item_image_url'] ?? '').toString();
    final addr = (d['item_address'] ?? '').toString();
    final created = _date10(d['created_at']);
    final expiry = _date10(d['expiry_date'] ?? d['item_expiry_date']);

    final me = _myId();
    final iAmDonor = donorId == me;
    final iAmRecipient = recipientId == me;
    final canConfirm = status == 'ACCEPTED' && (iAmDonor || iAmRecipient);

    final titleColor = _isDark ? Colors.white : _ink;
    final subColor = _isDark
        ? Colors.white.withValues(alpha: 0.9)
        : _ink.withValues(alpha: 0.75);

    return _card(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 64,
              height: 64,
              color: _isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.03),
              child: itemImg.trim().isNotEmpty
                  ? Image.network(
                      itemImg,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_outlined,
                        color: _isDark ? Colors.white : _ink,
                      ),
                    )
                  : Icon(
                      Icons.volunteer_activism,
                      color: _isDark ? Colors.white : _ink,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _statusPill(status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tür: $type • Oluşturma: $created',
                  style: TextStyle(
                    color: subColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (expiry.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Son tüketim: $expiry',
                    style: TextStyle(
                      color: subColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (addr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    addr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (itemDesc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    itemDesc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (canConfirm) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _donationApi.confirmPickup(donationId: id);
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                iAmDonor
                                    ? 'Teslim ettin olarak işaretlendi'
                                    : 'Teslim aldın olarak işaretlendi',
                              ),
                            ),
                          );
                          await _loadAll();
                        } catch (e) {
                          if (!mounted) return;
                          final msg = e.toString().replaceFirst(
                            'Exception: ',
                            '',
                          );
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(iAmDonor ? 'Teslim Ettim' : 'Teslim Aldım'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final id = (item['id'] as num?)?.toInt() ?? 0;
    if (id <= 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Bu bağış kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _itemService.removeMyItem(id: id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bağış silindi.')));
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openEditItemSheet(Map<String, dynamic> item) async {
    final id = (item['id'] as num?)?.toInt() ?? 0;
    if (id <= 0) return;

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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                                  : 'Son tüketim: ${expiry!.toIso8601String().substring(0, 10)}',
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
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _myPostCard(Map<String, dynamic> item, {required bool isDonor}) {
    final id = (item['id'] as num?)?.toInt() ?? 0;

    final title = (item['name'] ?? 'Ürün').toString();
    final desc = (item['description'] ?? '').toString();
    final category = (item['category'] ?? '').toString();

    final status = _statusOf(item); // raw english (logic)

    final expiry = _date10(item['expiry_date'] ?? item['expiryDate']);
    final address = (item['address'] ?? item['fridge_address'] ?? '')
        .toString();
    final img = (item['image_url'] ?? item['imageUrl'] ?? '').toString();

    const fallback =
        "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=60";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18, color: _ink),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(status),
                const SizedBox(width: 6),
                if (isDonor)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: _ink),
                    onSelected: (v) {
                      if (v == 'edit') _openEditItemSheet(item);
                      if (v == 'delete') _deleteItem(item);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      PopupMenuItem(value: 'delete', child: Text('Sil')),
                    ],
                  ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              img.isNotEmpty ? img : fallback,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Image.network(fallback, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: _ink,
                      ),
                    ),
                  ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _ink.withValues(alpha: 0.75),
                    ),
                  ),
                ],
                if (expiry.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Son tüketim: $expiry',
                    style: TextStyle(
                      fontSize: 12,
                      color: _ink.withValues(alpha: 0.75),
                    ),
                  ),
                ],
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: _ink),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  _postSummaryText(item),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isDonor
                            ? () {
                                context.push('/donations', extra: {'itemId': id});
                              }
                            : null,
                        icon: const Icon(Icons.inbox_outlined),
                        label: const Text('İstekleri Yönet'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _postSummaryText(Map<String, dynamic> item) {
    final pendingRaw =
        item['pending_request_count'] ?? item['pendingRequestCount'] ?? 0;
    final pending = (pendingRaw is num)
        ? pendingRaw.toInt()
        : int.tryParse('$pendingRaw') ?? 0;

    final acceptedName =
        item['accepted_recipient_full_name'] ??
        item['acceptedRecipientFullName'];
    final donorConfirmed = item['donor_confirmed_at'] != null;
    final recipientConfirmed = item['recipient_confirmed_at'] != null;

    if (acceptedName != null && acceptedName.toString().trim().isNotEmpty) {
      if (donorConfirmed && recipientConfirmed) {
        return 'Bağış $acceptedName ile tamamlandı.';
      }
      return 'Bağış $acceptedName için ayrıldı.';
    }

    if (pending > 0) {
      return '$pending istek var • İnceleyebilirsin.';
    }

    return 'Henüz istek yok.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final name = (user?.fullName ?? user?.username ?? 'Kullanıcı').trim();
    final username = (user?.username ?? '').trim();
    final bio = (user?.bio ?? '').trim();
    final role = (user?.role ?? '').trim();
    final points = user?.kindnessPoints ?? 0;

    final isNeedy = role.toUpperCase() == 'NEEDY';
    final isDonor = _isDonorRole(role);

    final visibleItems = _myPublicItems
        .where((e) => _statusOf(e) != 'REMOVED')
        .toList();

    final avatarUrl = (user?.avatarUrl ?? '').trim();

    final header = Container(
      decoration: BoxDecoration(
        color: _isDark ? Colors.transparent : _brand,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: _card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatarLikeHome(avatarUrl, radius: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: TextStyle(
                          color: _ink.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill('Rol: ${_roleText(role)}'),
                        _pill('Puan: $points'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return AppShell(
      withBackground: !widget.embedded,
      appBar: buildGlassAppBar(
        context: context,
        title: 'Profil',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: user == null ? null : _openEditProfileSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
        bottom: isNeedy
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
                  tabs: const [
                    Tab(text: 'Bağışlarım'),
                    Tab(text: 'İşlemlerim'),
                  ],
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: _card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bir şeyler ters gitti',
                      style: TextStyle(
                        color: _isDark ? Colors.white : _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : _ink.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadAll,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Yenile'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                header,
                Expanded(
                  child: isNeedy
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                          children: [
                            if (_myDonations.isEmpty)
                              _card(
                                child: Text(
                                  'Henüz bağış geçmişin yok.',
                                  style: TextStyle(
                                    color: _isDark ? Colors.white : _ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            else
                              ..._myDonations.map(
                                (d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _donationHistoryCard(d),
                                ),
                              ),
                          ],
                        )
                      : TabBarView(
                          controller: _tabCtrl,
                          children: [
                            ListView(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                18,
                              ),
                              children: [
                                if (!isDonor)
                                  _card(
                                    child: Text(
                                      'Bu hesap türünde “Bağışlarım” bölümü yok.',
                                      style: TextStyle(
                                        color: _isDark ? Colors.white : _ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                else if (visibleItems.isEmpty)
                                  _card(
                                    child: Text(
                                      'Henüz yayınladığın bağış yok.',
                                      style: TextStyle(
                                        color: _isDark ? Colors.white : _ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                else
                                  ...visibleItems.map(
                                    (i) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _myPostCard(i, isDonor: isDonor),
                                    ),
                                  ),
                              ],
                            ),
                            ListView(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                18,
                              ),
                              children: [
                                if (_myDonations.isEmpty)
                                  _card(
                                    child: Text(
                                      'Henüz bağış geçmişin yok.',
                                      style: TextStyle(
                                        color: _isDark ? Colors.white : _ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                else
                                  ..._myDonations.map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _donationHistoryCard(d),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

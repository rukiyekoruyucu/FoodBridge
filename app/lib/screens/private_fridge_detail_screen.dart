// lib/screens/private_fridge_detail_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/widgets/add_donation_sheet.dart';
import 'package:foodbridge/services/private_fridge_api_service.dart';
import 'package:foodbridge/services/upload_service.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class PrivateFridgeDetailScreen extends ConsumerStatefulWidget {
  final String fridgeId;
  final String fridgeName;
  final String userRole;

  const PrivateFridgeDetailScreen({
    super.key,
    required this.fridgeId,
    required this.fridgeName,
    required this.userRole,
  });

  @override
  ConsumerState<PrivateFridgeDetailScreen> createState() =>
      _PrivateFridgeDetailScreenState();
}

class _PrivateFridgeDetailScreenState
    extends ConsumerState<PrivateFridgeDetailScreen> {
  final _api = PrivateFridgeApiService();
  final UploadService _upload = createUploadService();
  final _picker = ImagePicker();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _s(dynamic v) => (v ?? "").toString();
  int _i(dynamic v) => v is num ? v.toInt() : (int.tryParse(_s(v)) ?? 0);

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = _s(v);
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _api.listItemsInPrivateFridge(widget.fridgeId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---------- LIGHT/DARK helpers for sheets ----------
  BoxDecoration _sheetDecoration(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    if (isDark) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      );
    }

    return BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 30,
          offset: const Offset(0, -12),
        ),
      ],
    );
  }

  Color _sheetTitleColor(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return isDark ? Colors.white : _ink;
  }

  TextStyle _sheetInputStyle(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? Colors.white : _ink,
      fontWeight: FontWeight.w800,
    );
  }

  InputDecoration _sheetInputDeco(BuildContext ctx, String hint) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    if (isDark) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.36)),
        ),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _ink.withValues(alpha: 0.55)),
      filled: true,
      fillColor: const Color(0xFFF6F7FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _brand.withValues(alpha: 0.70),
          width: 1.2,
        ),
      ),
    );
  }

  BoxDecoration _sheetBox(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    if (isDark) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      );
    }

    return BoxDecoration(
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
    );
  }

  // ---------- Add Item ----------
  Future<void> _openAddItemSheet() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: "1");
    final catCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    XFile? picked;
    Uint8List? pickedBytes;
    DateTime? expiry;

    bool sheetLoading = false;
    String? sheetError;

    Future<void> pickImage(StateSetter setModal) async {
      if (kIsWeb) {
        setModal(
          () => sheetError =
              "Web'de fotoğraf yükleme kapalı. Android cihazda test et.",
        );
        return;
      }
      try {
        final x = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1600,
        );
        if (x == null) return;

        final bytes = await x.readAsBytes();
        setModal(() {
          picked = x;
          pickedBytes = bytes;
        });
      } catch (e) {
        setModal(() => sheetError = "Foto seçilemedi: $e");
      }
    }

    Future<void> pickExpiry(StateSetter setModal) async {
      final now = DateTime.now();
      final d = await showDatePicker(
        context: context,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365 * 3)),
        initialDate: expiry ?? now,
        builder: (ctx, child) {
          if (Theme.of(ctx).brightness == Brightness.dark) return child!;
          final theme = Theme.of(ctx);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: _brand,
                onPrimary: Colors.white,
                onSurface: _ink,
              ),
            ),
            child: child!,
          );
        },
      );
      if (d == null) return;
      setModal(() => expiry = d);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;

        return StatefulBuilder(
          builder: (ctx, setModal) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final titleColor = _sheetTitleColor(ctx);

            return Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
              decoration: _sheetDecoration(ctx),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Ürün Ekle",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (sheetError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.withValues(
                                alpha: isDark ? 0.35 : 0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            sheetError!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      Container(
                        decoration: _sheetBox(ctx),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 64,
                                height: 64,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : const Color(0xFFF6F7FB),
                                child: pickedBytes == null
                                    ? Icon(
                                        Icons.image_outlined,
                                        color: isDark ? Colors.white : _ink,
                                      )
                                    : Image.memory(
                                        pickedBytes!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                picked == null
                                    ? "Fotoğraf ekle (opsiyonel)"
                                    : "Fotoğraf seçildi",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: sheetLoading
                                  ? null
                                  : () => pickImage(setModal),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : _brand.withValues(alpha: 0.55),
                                ),
                                foregroundColor: isDark ? Colors.white : _brand,
                              ),
                              child: const Text("Seç"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      TextField(
                        controller: nameCtrl,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(ctx, "Ad (zorunlu)"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(ctx, "Adet (zorunlu)"),
                      ),

                      const SizedBox(height: 10),
                      Container(
                        decoration: _sheetBox(ctx),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                expiry == null
                                    ? "Son kullanma (zorunlu) seçilmedi"
                                    : "Son kullanma: ${expiry!.day.toString().padLeft(2, '0')}.${expiry!.month.toString().padLeft(2, '0')}.${expiry!.year}",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: sheetLoading
                                  ? null
                                  : () => pickExpiry(setModal),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : _brand,
                              ),
                              child: const Text("Seç"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      TextField(
                        controller: catCtrl,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(
                          ctx,
                          "Kategori (opsiyonel)",
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(
                          ctx,
                          "Açıklama (opsiyonel)",
                        ),
                      ),

                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: sheetLoading
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  final qty =
                                      int.tryParse(qtyCtrl.text.trim()) ?? 0;

                                  if (name.length < 2) {
                                    setModal(
                                      () => sheetError =
                                          "Ürün adı en az 2 karakter olmalı.",
                                    );
                                    return;
                                  }
                                  if (qty <= 0) {
                                    setModal(
                                      () => sheetError = "Adet 1+ olmalı.",
                                    );
                                    return;
                                  }
                                  if (expiry == null) {
                                    setModal(
                                      () => sheetError =
                                          "Son kullanma tarihini seçmelisin.",
                                    );
                                    return;
                                  }

                                  setModal(() {
                                    sheetLoading = true;
                                    sheetError = null;
                                  });

                                  try {
                                    String? imageUrl;
                                    if (picked != null) {
                                      imageUrl = await _upload
                                          .uploadImageFromPath(
                                            picked!.path,
                                            folder: 'items-private',
                                          );
                                    }

                                    await _api.addItemToPrivateFridge(
                                      widget.fridgeId,
                                      name: name,
                                      quantity: qty,
                                      category: catCtrl.text.trim().isEmpty
                                          ? null
                                          : catCtrl.text.trim(),
                                      description: descCtrl.text.trim().isEmpty
                                          ? null
                                          : descCtrl.text.trim(),
                                      expiryDate: expiry!,
                                      imageUrl: imageUrl,
                                    );

                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    await _load();
                                  } catch (e) {
                                    setModal(() {
                                      sheetLoading = false;
                                      sheetError = e.toString();
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : _brand,
                            foregroundColor: isDark
                                ? const Color(0xFF0B1220)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: sheetLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Ekle",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Private Fridge içindeki item'ı güncelleme
  Future<void> _openEditItemSheet(Map<String, dynamic> it) async {
    final itemId = _i(it["id"]);

    final nameCtrl = TextEditingController(text: _s(it["name"]).trim());
    final qtyCtrl = TextEditingController(
      text: (_i(it["quantity"]) > 0 ? _i(it["quantity"]) : 1).toString(),
    );
    final catCtrl = TextEditingController(text: _s(it["category"]).trim());
    final descCtrl = TextEditingController(
      text: _s(it["description"] ?? it["desc"]).trim(),
    );
    final unitCtrl = TextEditingController(text: _s(it["unit"]).trim());

    XFile? picked;
    Uint8List? pickedBytes;

    final currentImageUrl = _s(it["imageUrl"]).isNotEmpty
        ? _s(it["imageUrl"])
        : _s(it["image_url"]);
    DateTime? expiry = _parseDate(it["expiryDate"] ?? it["expiry_date"]);

    bool sheetLoading = false;
    String? sheetError;

    Future<void> pickImage(StateSetter setModal) async {
      if (kIsWeb) {
        setModal(
          () => sheetError =
              "Web'de fotoğraf yükleme kapalı. Android cihazda test et.",
        );
        return;
      }
      try {
        final x = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1600,
        );
        if (x == null) return;

        final bytes = await x.readAsBytes();
        setModal(() {
          picked = x;
          pickedBytes = bytes;
        });
      } catch (e) {
        setModal(() => sheetError = "Foto seçilemedi: $e");
      }
    }

    Future<void> pickExpiry(StateSetter setModal) async {
      final now = DateTime.now();
      final d = await showDatePicker(
        context: context,
        firstDate: now.subtract(const Duration(days: 1)),
        lastDate: now.add(const Duration(days: 365 * 3)),
        initialDate: expiry ?? now,
        builder: (ctx, child) {
          if (Theme.of(ctx).brightness == Brightness.dark) return child!;
          final theme = Theme.of(ctx);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: _brand,
                onPrimary: Colors.white,
                onSurface: _ink,
              ),
            ),
            child: child!,
          );
        },
      );
      if (d == null) return;
      setModal(() => expiry = d);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;

        return StatefulBuilder(
          builder: (ctx, setModal) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final titleColor = _sheetTitleColor(ctx);

            return Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
              decoration: _sheetDecoration(ctx),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Ürün Düzenle",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (sheetError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.withValues(
                                alpha: isDark ? 0.35 : 0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            sheetError!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      Container(
                        decoration: _sheetBox(ctx),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 64,
                                height: 64,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : const Color(0xFFF6F7FB),
                                child: pickedBytes != null
                                    ? Image.memory(
                                        pickedBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : (currentImageUrl.isNotEmpty
                                          ? Image.network(
                                              currentImageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              Icons.image_outlined,
                                              color: isDark
                                                  ? Colors.white
                                                  : _ink,
                                            )),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                picked != null
                                    ? "Yeni foto seçildi"
                                    : (currentImageUrl.isNotEmpty
                                          ? "Mevcut fotoğraf"
                                          : "Fotoğraf yok (opsiyonel)"),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: sheetLoading
                                  ? null
                                  : () => pickImage(setModal),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : _brand.withValues(alpha: 0.55),
                                ),
                                foregroundColor: isDark ? Colors.white : _brand,
                              ),
                              child: const Text("Seç"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      TextField(
                        controller: nameCtrl,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(ctx, "Ad (zorunlu)"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(ctx, "Adet (zorunlu)"),
                      ),

                      const SizedBox(height: 10),
                      Container(
                        decoration: _sheetBox(ctx),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                expiry == null
                                    ? "Son kullanma seçilmedi"
                                    : "Son kullanma: ${expiry!.day.toString().padLeft(2, '0')}.${expiry!.month.toString().padLeft(2, '0')}.${expiry!.year}",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: sheetLoading
                                  ? null
                                  : () => pickExpiry(setModal),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : _brand,
                              ),
                              child: const Text("Seç"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      TextField(
                        controller: catCtrl,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(
                          ctx,
                          "Kategori (opsiyonel)",
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: unitCtrl,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(ctx, "Birim (opsiyonel)"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: _sheetInputStyle(ctx),
                        decoration: _sheetInputDeco(
                          ctx,
                          "Açıklama (opsiyonel)",
                        ),
                      ),

                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: sheetLoading
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  final qty =
                                      int.tryParse(qtyCtrl.text.trim()) ?? 0;

                                  if (name.length < 2) {
                                    setModal(
                                      () => sheetError =
                                          "Ürün adı en az 2 karakter olmalı.",
                                    );
                                    return;
                                  }
                                  if (qty <= 0) {
                                    setModal(
                                      () => sheetError = "Adet 1+ olmalı.",
                                    );
                                    return;
                                  }
                                  if (expiry == null) {
                                    setModal(
                                      () => sheetError =
                                          "Son kullanma tarihini seçmelisin.",
                                    );
                                    return;
                                  }

                                  setModal(() {
                                    sheetLoading = true;
                                    sheetError = null;
                                  });

                                  try {
                                    String imageUrl = currentImageUrl;
                                    if (picked != null) {
                                      final uploaded = await _upload
                                          .uploadImageFromPath(
                                            picked!.path,
                                            folder: 'items-private',
                                          );
                                      if (uploaded.trim().isNotEmpty)
                                        imageUrl = uploaded.trim();
                                    }

                                    await _api.updatePrivateItem(
                                      widget.fridgeId,
                                      itemId,
                                      name: name,
                                      quantity: qty,
                                      category: catCtrl.text.trim().isEmpty
                                          ? null
                                          : catCtrl.text.trim(),
                                      unit: unitCtrl.text.trim().isEmpty
                                          ? null
                                          : unitCtrl.text.trim(),
                                      description: descCtrl.text.trim().isEmpty
                                          ? null
                                          : descCtrl.text.trim(),
                                      expiryDate: expiry,
                                      imageUrl: imageUrl.trim().isEmpty
                                          ? null
                                          : imageUrl,
                                    );

                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    await _load();
                                  } catch (e) {
                                    setModal(() {
                                      sheetLoading = false;
                                      sheetError = e.toString();
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : _brand,
                            foregroundColor: isDark
                                ? const Color(0xFF0B1220)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: sheetLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Kaydet",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteItem(int itemId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ürün Silinsin mi?"),
        content: const Text("Bu ürün buzdolabından kaldırılacak."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.deletePrivateItem(widget.fridgeId, itemId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ürün silindi.")));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ---------- Grid card (theme aware) ----------
  Widget _gridCard({required Widget child, VoidCallback? onTap}) {
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

  @override
  Widget build(BuildContext context) {
    final content = _loading
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
        : (_items.isEmpty)
        ? Center(
            child: Text(
              "Bu buzdolabında ürün yok.",
              style: TextStyle(
                color: _isDark ? Colors.white : _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : LayoutBuilder(
            builder: (_, c) {
              final w = c.maxWidth;
              final cross = w >= 900 ? 4 : (w >= 600 ? 3 : 2);

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.88,
                ),
                itemCount: _items.length,
                itemBuilder: (_, idx) {
                  final it = _items[idx];
                  final id = _i(it["id"]);
                  final name = _s(it["name"]).isEmpty ? "Ürün" : _s(it["name"]);
                  final imageUrl = _s(it["imageUrl"]).isNotEmpty
                      ? _s(it["imageUrl"])
                      : _s(it["image_url"]);
                  final expiry = _parseDate(
                    it["expiryDate"] ?? it["expiry_date"],
                  );
                  final left = _daysLeft(expiry);

                  final leftText = (left == null)
                      ? "Tarih yok"
                      : (left < 0 ? "SÜRESİ GEÇTİ" : "$left gün");

                  final titleColor = _isDark ? Colors.white : _ink;

                  return _gridCard(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(name),
                          content: Text("Kalan: $leftText"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Kapat"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                color: _isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : const Color(0xFFF6F7FB),
                                child: imageUrl.isEmpty
                                    ? Icon(
                                        Icons.inventory_2_outlined,
                                        color: _isDark ? Colors.white : _ink,
                                        size: 34,
                                      )
                                    : Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: _isDark ? Colors.white : _ink,
                                ),
                                onSelected: (v) {
                                  if (v == "edit") {
                                    _openEditItemSheet(it);
                                    return;
                                  }
                                  if (v == "donate") {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => AddDonationSheet(
                                        userRole: widget.userRole,
                                        initialName: name,
                                        initialDescription:
                                            (it["description"] ??
                                                    it["desc"] ??
                                                    "")
                                                .toString(),
                                        initialQuantity: (it["quantity"] is num)
                                            ? (it["quantity"] as num).toInt()
                                            : int.tryParse(
                                                (it["quantity"] ?? "")
                                                    .toString(),
                                              ),
                                        initialExpiry: _parseDate(
                                          it["expiryDate"] ??
                                              it["expiry_date"] ??
                                              it["expiry"],
                                        ),
                                        initialCategory: (it["category"] ?? "")
                                            .toString(),
                                        initialImageUrl:
                                            (it["imageUrl"] ??
                                                    it["image_url"] ??
                                                    "")
                                                .toString(),
                                      ),
                                    );
                                    return;
                                  }
                                  if (v == "del") {
                                    _deleteItem(id);
                                    return;
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: "edit",
                                    child: Text("Düzenle"),
                                  ),
                                  PopupMenuItem(
                                    value: "donate",
                                    child: Text("Bağışla"),
                                  ),
                                  PopupMenuItem(
                                    value: "del",
                                    child: Text("Sil"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : _brand.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : _brand.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              leftText,
                              style: TextStyle(
                                color: _isDark
                                    ? Colors.white.withValues(alpha: 0.95)
                                    : _ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
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

    return AppShell(
      appBar: buildGlassAppBar(
        context: context,
        title: widget.fridgeName,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddItemSheet,
        backgroundColor: _isDark ? null : _brand,
        foregroundColor: _isDark ? null : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Ürün Ekle"),
      ),
      body: content,
    );
  }
}

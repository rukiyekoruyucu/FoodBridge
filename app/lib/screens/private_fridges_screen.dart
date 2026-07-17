import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/models/private_fridge.dart';
import 'package:foodbridge/screens/private_fridge_detail_screen.dart';
import 'package:foodbridge/services/location_service.dart';
import 'package:foodbridge/services/private_fridge_api_service.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class PrivateFridgesScreen extends ConsumerStatefulWidget {
  final String userRole;
  const PrivateFridgesScreen({super.key, required this.userRole});

  @override
  ConsumerState<PrivateFridgesScreen> createState() =>
      _PrivateFridgesScreenState();
}

class _PrivateFridgesScreenState extends ConsumerState<PrivateFridgesScreen> {
  final _api = PrivateFridgeApiService();
  final _location = LocationService();

  bool _loading = true;
  String? _error;

  List<PrivateFridge> _fridges = const [];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fridges = await _api.listMyPrivateFridges();
      if (!mounted) return;
      setState(() {
        _fridges = fridges;
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

  // ---- theme aware card ----
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

  InputDecoration _sheetInput(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
      labelStyle: TextStyle(color: _isDark ? Colors.white70 : _ink.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _isDark ? Colors.white : AppShell.kGreen, width: 1.5),
      ),
    );
  }

  Future<void> _openCreateFridgeSheet() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    bool saving = false;
    String? sheetError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        final decoration = isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -12),
                  ),
                ],
              );

        final titleColor = isDark ? Colors.white : AppShell.kInk;
        final hintColor = isDark ? Colors.white : AppShell.kInk;

        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
              decoration: decoration,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        "Yeni Buzdolabı Oluştur",
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),

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

                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(
                          color: hintColor,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: _sheetInput("Ad (zorunlu)"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl,
                        style: TextStyle(
                          color: hintColor,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: _sheetInput("Açıklama (opsiyonel)"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: addrCtrl,
                        style: TextStyle(
                          color: hintColor,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: _sheetInput("Adres (opsiyonel)"),
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  if (name.length < 2) {
                                    setModal(
                                      () => sheetError =
                                          "Ad en az 2 karakter olmalı.",
                                    );
                                    return;
                                  }

                                  setModal(() {
                                    saving = true;
                                    sheetError = null;
                                  });

                                  try {
                                    final pos = await _location
                                        .getCurrentLocation();

                                    final created = await _api
                                        .createPrivateFridge(
                                          name: name,
                                          description:
                                              descCtrl.text.trim().isEmpty
                                              ? null
                                              : descCtrl.text.trim(),
                                          latitude: pos.latitude,
                                          longitude: pos.longitude,
                                          address: addrCtrl.text.trim().isEmpty
                                              ? null
                                              : addrCtrl.text.trim(),
                                        );

                                    if (!mounted) return;
                                    Navigator.pop(context);

                                    setState(() {
                                      _fridges = [created, ..._fridges];
                                    });
                                  } catch (e) {
                                    setModal(() {
                                      saving = false;
                                      sheetError = e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      );
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white
                                : AppShell.kGreen,
                            foregroundColor: isDark
                                ? const Color(0xFF0B1220)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Oluştur",
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

  Future<void> _deleteFridge(PrivateFridge f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Buzdolabı silinsin mi?"),
        content: const Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _api.deletePrivateFridge(f.id);
      if (!mounted) return;
      setState(() {
        _fridges = _fridges.where((x) => x.id != f.id).toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Silindi.")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _fridgeCard(PrivateFridge f) {
    final title = f.name.trim().isEmpty ? "Buzdolabı" : f.name.trim();
    final desc = (f.description ?? '').trim();
    final addr = (f.address ?? '').trim();

    final titleColor = _isDark ? Colors.white : _ink;
    final subColor = _isDark
        ? Colors.white.withValues(alpha: 0.9)
        : _ink.withValues(alpha: 0.75);
    final iconColor = _isDark ? Colors.white : _ink;

    return _card(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrivateFridgeDetailScreen(
                fridgeId: f.id,
                fridgeName: title,
                userRole: widget.userRole,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : AppShell.kGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.kitchen_outlined, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subColor,
                          fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: iconColor),
                onSelected: (v) {
                  if (v == 'del') _deleteFridge(f);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'del', child: Text("Sil")),
                ],
              ),
            ],
          ),
        ),
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
        : (_fridges.isEmpty)
        ? Center(
            child: Text(
              "Henüz kişisel buzdolabın yok.",
              style: TextStyle(
                color: _isDark ? Colors.white : _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            itemCount: _fridges.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _fridgeCard(_fridges[i]),
          );

    return AppShell(
      appBar: buildGlassAppBar(
        context: context,
        title: "Kişisel Buzdolaplarım",
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _openCreateFridgeSheet,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}

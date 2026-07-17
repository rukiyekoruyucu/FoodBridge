
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/upload_service.dart';
import '../services/location_service.dart';
import '../services/item_service.dart';
import '../screens/map_screen.dart';

class AddDonationSheet extends StatefulWidget {
  final String userRole; // NEEDY | PERSONAL | CORPORATE

  final String? initialName;
  final String? initialDescription;
  final int? initialQuantity;
  final DateTime? initialExpiry;
  final String? initialCategory;
  final String? initialImageUrl;

  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const AddDonationSheet({
    super.key,
    required this.userRole,
    this.initialName,
    this.initialDescription,
    this.initialQuantity,
    this.initialExpiry,
    this.initialCategory,
    this.initialImageUrl,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<AddDonationSheet> createState() => _AddDonationSheetState();
}

class _AddDonationSheetState extends State<AddDonationSheet> {
  static const Color kGreen = Color(0xFF16A34A);
  static const Color kTextDark = Color(0xFF0B1220);

  final _locationService = LocationService();
  final _upload = createUploadService();
  final _itemService = ItemService();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  final _picker = ImagePicker();

  XFile? _pickedX;
  Uint8List? _pickedBytes;

  DateTime? _expiry;
  bool _loading = false;
  String? _error;

  double? _lat;
  double? _lng;

  String? _category;
  String? _existingImageUrl;

  static const _allowedCats = <String>{'food', 'drink', 'other'};

  @override
  void initState() {
    super.initState();

    if ((widget.initialName ?? '').trim().isNotEmpty) {
      _nameCtrl.text = widget.initialName!.trim();
    }
    if ((widget.initialDescription ?? '').trim().isNotEmpty) {
      _descCtrl.text = widget.initialDescription!.trim();
    }
    if (widget.initialQuantity != null && widget.initialQuantity! > 0) {
      _qtyCtrl.text = widget.initialQuantity!.toString();
    }
    if ((widget.initialAddress ?? '').trim().isNotEmpty) {
      _addrCtrl.text = widget.initialAddress!.trim();
    }

    _expiry = widget.initialExpiry;

    final rawCat = (widget.initialCategory ?? '').trim().toLowerCase();
    _category = _allowedCats.contains(rawCat) ? rawCat : null;

    final img = (widget.initialImageUrl ?? '').trim();
    _existingImageUrl = img.isEmpty ? null : img;

    if (widget.initialLat != null && widget.initialLng != null) {
      _lat = widget.initialLat;
      _lng = widget.initialLng;
    } else {
      _useCurrentLocation();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _fg => _isDark ? Colors.white : kGreen;
  Color get _muted => _isDark
      ? Colors.white.withValues(alpha: 0.85)
      : kGreen.withValues(alpha: 0.85);

  BoxDecoration _surfaceBox() {
    // Kart yüzeyleri
    if (_isDark) {
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

  InputDecoration _inputDeco(String hint) {
    if (_isDark) {
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

    // Light: beyaz alan + yeşil vurgu, yazı yeşil
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: kGreen.withValues(alpha: 0.55)),
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
          color: kGreen.withValues(alpha: 0.70),
          width: 1.2,
        ),
      ),
    );
  }

  TextStyle _fieldLabelStyle() => TextStyle(
    color: _fg.withValues(alpha: 0.95),
    fontWeight: FontWeight.w900,
  );

  TextStyle _textStyle() => TextStyle(color: _fg, fontWeight: FontWeight.w700);

  TextStyle _inputTextStyle() => TextStyle(
    color: _isDark ? Colors.white : const Color(0xFF0F172A), // AppShell.kInk
    fontWeight: FontWeight.w800,
  );

  Future<void> _pickPhoto() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (x == null) return;

      final bytes = await x.readAsBytes();

      setState(() {
        _pickedX = x;
        _pickedBytes = bytes;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = "Foto seçilemedi: $e");
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      initialDate: _expiry ?? now,
      builder: (ctx, child) {
        // Light'ta yeşil aksan
        if (_isDark) return child!;
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: kGreen,
              onPrimary: Colors.white,
              onSurface: kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _expiry = picked);
  }

  int? _quantityOrNull() {
    final raw = _qtyCtrl.text.trim();
    if (raw.isEmpty) return null;
    final q = int.tryParse(raw);
    if (q == null || q < 1) return null;
    return q;
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pos = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Konum alınamadı. Konum iznini kontrol et.\nDetay: $e";
      });
    }
  }

  Future<void> _pickFromMap() async {
    final LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          userRole: widget.userRole,
          pickerMode: true,
          initialPick: (_lat != null && _lng != null)
              ? LatLng(_lat!, _lng!)
              : null,
        ),
      ),
    );

    if (picked == null) return;
    setState(() {
      _lat = picked.latitude;
      _lng = picked.longitude;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (widget.userRole.trim().toUpperCase() == 'NEEDY') {
      setState(() => _error = "İhtiyaç sahibi hesapları bağış ekleyemez.");
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      setState(() => _error = "Ürün adı en az 2 karakter olmalı.");
      return;
    }

    if (_expiry == null) {
      setState(() => _error = "Son tüketim tarihini seçmelisin.");
      return;
    }

    if (_lat == null || _lng == null) {
      setState(() => _error = "Konum seçmelisin (mevcut veya haritadan).");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? imageUrl = _existingImageUrl;

      // Android: upload çalışır. Web: upload yok (build bozulmasın).
      if (!kIsWeb && _pickedX != null) {
        imageUrl = await _upload.uploadImageFromPath(
          _pickedX!.path,
          folder: 'items-public',
        );
      }

      await _itemService.createPublicItem(
        name: name,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        category: _category,
        quantity: _quantityOrNull(),
        expiryDate: _expiry!,
        lat: _lat!,
        lng: _lng!,
        address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Widget _field(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _fieldLabelStyle()),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = 16 + MediaQuery.of(context).viewInsets.bottom;

    // Light: beyaz sheet, Dark: gradient
    final sheetDecoration = BoxDecoration(
      color: _isDark ? null : Colors.white,
      gradient: _isDark
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
            )
          : null,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      boxShadow: [
        if (!_isDark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -12),
          ),
      ],
    );

    return Container(
      decoration: sheetDecoration,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : kGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Yeni Bağış Ekle",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _isDark ? Colors.white : kGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(
                        alpha: _isDark ? 0.18 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withValues(
                          alpha: _isDark ? 0.35 : 0.25,
                        ),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: _isDark ? Colors.white : Colors.red.shade700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Photo row
                Container(
                  decoration: _surfaceBox(),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: _isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFF6F7FB),
                          child: (_pickedBytes != null)
                              ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                              : (_existingImageUrl != null)
                              ? Image.network(
                                  _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_outlined,
                                    color: _isDark ? Colors.white : kGreen,
                                  ),
                                )
                              : Icon(
                                  Icons.image_outlined,
                                  color: _isDark ? Colors.white : kGreen,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedBytes == null
                              ? (kIsWeb
                                    ? "Foto seç (web: sadece önizleme)"
                                    : "Fotoğraf ekle (opsiyonel)")
                              : "Fotoğraf seçildi",
                          style: _textStyle(),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _loading ? null : _pickPhoto,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _isDark
                                ? Colors.white.withValues(alpha: 0.65)
                                : kGreen.withValues(alpha: 0.55),
                          ),
                          foregroundColor: _isDark ? Colors.white : kGreen,
                        ),
                        child: const Text("Seç"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _field(
                  "Ürün adı",
                  TextField(
                    controller: _nameCtrl,
                    style: _inputTextStyle(),
                    decoration: _inputDeco("Örn: Süt, Ekmek, Konserve..."),
                    cursorColor: _isDark ? Colors.white : kGreen,
                  ),
                ),

                _field(
                  "Açıklama (opsiyonel)",
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    style: _inputTextStyle(),
                    decoration: _inputDeco("Not ekleyebilirsin"),
                    cursorColor: _isDark ? Colors.white : kGreen,
                  ),
                ),

                _field(
                  "Kategori (opsiyonel)",
                  DropdownButtonFormField<String?>(
                    value: _category,
                    dropdownColor: _isDark
                        ? const Color(0xFF0B1220)
                        : Colors.white,
                    style: _inputTextStyle(),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text("Seçilmedi"),
                      ),
                      DropdownMenuItem<String?>(
                        value: "food",
                        child: Text("Gıda"),
                      ),
                      DropdownMenuItem<String?>(
                        value: "drink",
                        child: Text("İçecek"),
                      ),
                      DropdownMenuItem<String?>(
                        value: "other",
                        child: Text("Diğer"),
                      ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                    decoration: _inputDeco(""),
                    iconEnabledColor: _isDark ? Colors.white : kGreen,
                  ),
                ),

                _field(
                  "Adet (opsiyonel)",
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    style: _inputTextStyle(),
                    decoration: _inputDeco("Boş bırak = 1"),
                    cursorColor: _isDark ? Colors.white : kGreen,
                  ),
                ),

                Container(
                  decoration: _surfaceBox(),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _expiry == null
                              ? "Son tüketim tarihi (zorunlu) seçilmedi"
                              : "Son tüketim: ${_expiry!.day.toString().padLeft(2, '0')}.${_expiry!.month.toString().padLeft(2, '0')}.${_expiry!.year}",
                          style: TextStyle(
                            color: _fg.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loading ? null : _pickExpiry,
                        style: TextButton.styleFrom(
                          foregroundColor: _isDark ? Colors.white : kGreen,
                        ),
                        child: const Text("Tarih Seç"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: _surfaceBox(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Konum (zorunlu)", style: _fieldLabelStyle()),
                      const SizedBox(height: 8),
                      Text(
                        (_lat == null || _lng == null)
                            ? "Seçilmedi"
                            : "Lat: ${_lat!.toStringAsFixed(5)}  Lon: ${_lng!.toStringAsFixed(5)}",
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addrCtrl,
                        style: _inputTextStyle(),
                        decoration: _inputDeco("Adres (opsiyonel)"),
                        cursorColor: _isDark ? Colors.white : kGreen,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _useCurrentLocation,
                              icon: Icon(
                                Icons.my_location,
                                color: _isDark ? Colors.white : kGreen,
                              ),
                              label: Text(
                                "Mevcut Konum",
                                style: TextStyle(
                                  color: _isDark ? Colors.white : kGreen,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isDark
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : kGreen.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _pickFromMap,
                              icon: Icon(
                                Icons.location_on_outlined,
                                color: _isDark ? Colors.white : kGreen,
                              ),
                              label: Text(
                                "Haritadan Seç",
                                style: TextStyle(
                                  color: _isDark ? Colors.white : kGreen,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isDark
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : kGreen.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDark ? Colors.white : kGreen,
                      foregroundColor: _isDark
                          ? const Color(0xFF0B1220)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "Bağışı Yayınla",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

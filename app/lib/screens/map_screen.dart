import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:foodbridge/services/location_service.dart';
import 'package:foodbridge/services/item_service.dart';
import 'package:foodbridge/services/donation_api_service.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class MapScreen extends StatefulWidget {
  final String userRole;

  final bool pickerMode;
  final LatLng? initialPick;
  final bool embedded;

  const MapScreen({
    super.key,
    required this.userRole,
    this.pickerMode = false,
    this.initialPick,
    this.embedded = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _locationService = LocationService();
  final _itemService = ItemService();

  bool loading = true;
  String? error;

  GoogleMapController? _mapCtrl;

  LatLng? myPos;
  double radiusKm = 10;

  final Map<MarkerId, Marker> _allMarkers = {};
  Map<MarkerId, Marker>? _filteredMarkers;
  List<Map> _items = [];

  final _searchCtrl = TextEditingController();
  String _query = "";

  LatLng? _pickedPos;

  final Map<String, BitmapDescriptor> _iconCache = {};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  @override
  void initState() {
    super.initState();
    if (widget.pickerMode && widget.initialPick != null) {
      _pickedPos = widget.initialPick;
    }
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double? _numToDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Future<void> _init() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final pos = await _locationService.getCurrentLocation();
      myPos = LatLng(pos.latitude, pos.longitude);

      if (!widget.pickerMode) {
        await _loadMarkers();
      }

      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  // ---------------- MARKER ICONS ----------------
  Future<BitmapDescriptor> _labelMarkerIcon(String text) async {
    final label = text.length > 18 ? "${text.substring(0, 18)}…" : text;

    const double paddingX = 18;
    const double paddingY = 12;
    const double radius = 18;
    const double fontSize = 26;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
    )..layout();

    final width = textPainter.width + paddingX * 2;
    final height = textPainter.height + paddingY * 2;

    final bgPaint = Paint()..color = AppShell.kGreen;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(radius),
    );
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(canvas, Offset(paddingX, paddingY));

    final tipPaint = Paint()..color = AppShell.kGreen;
    final path = Path()
      ..moveTo(width / 2 - 14, height)
      ..lineTo(width / 2 + 14, height)
      ..lineTo(width / 2, height + 18)
      ..close();
    canvas.drawPath(path, tipPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.ceil(), (height + 18).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _getIconForItem(int id, String name) async {
    final key = id.toString();
    final cached = _iconCache[key];
    if (cached != null) return cached;

    final icon = await _labelMarkerIcon(name);
    _iconCache[key] = icon;
    return icon;
  }

  Future<void> _loadMarkers() async {
    final me = myPos;
    if (me == null) return;

    final rows = await _itemService.getMapMarkers(
      lat: me.latitude,
      lng: me.longitude,
      radiusKm: radiusKm,
      limit: 300,
    );

    final nextMarkers = <MarkerId, Marker>{};
    final list = <Map>[];

    for (final raw in rows) {
      final item = raw as Map;

      final id = (item['id'] as num).toInt();
      final name = (item['name'] ?? 'Ürün').toString();

      final lat =
          _numToDouble(item['lat']) ??
          _numToDouble(item['latitude']) ??
          _numToDouble(item['fridge_latitude']);
      final lng =
          _numToDouble(item['lng']) ??
          _numToDouble(item['longitude']) ??
          _numToDouble(item['fridge_longitude']);

      if (lat == null || lng == null) continue;

      list.add(item);

      final markerId = MarkerId(id.toString());
      final icon = await _getIconForItem(id, name);

      nextMarkers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        icon: icon,
        onTap: () => _openItemSheet(item),
      );
    }

    if (!mounted) return;
    setState(() {
      _items = list;
      _allMarkers
        ..clear()
        ..addAll(nextMarkers);
    });

    _applyQueryFilter();
  }

  void _onSearchChanged(String v) {
    setState(() => _query = v);
    _applyQueryFilter();
  }

  void _applyQueryFilter() async {
    final q = _query.trim().toLowerCase();

    if (q.isEmpty) {
      if (!mounted) return;
      setState(() => _filteredMarkers = null);
      return;
    }

    final matchedIds = _items
        .where((m) {
          final name = (m['name'] ?? '').toString().toLowerCase();
          return name.contains(q);
        })
        .map((m) => (m['id'] as num).toInt().toString())
        .toSet();

    final filtered = <MarkerId, Marker>{};
    for (final e in _allMarkers.entries) {
      if (matchedIds.contains(e.key.value)) filtered[e.key] = e.value;
    }

    if (!mounted) return;
    setState(() => _filteredMarkers = filtered);

    if (filtered.isNotEmpty) {
      final first = filtered.values.first.position;
      await _mapCtrl?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: first, zoom: 15)),
      );
    }
  }

  String _dateText(dynamic v) {
    if (v == null) return "";
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking",
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openItemSheet(Map item) {
    final canRequest = widget.userRole == 'NEEDY';

    final title = (item['name'] ?? 'Ürün').toString();
    final desc = (item['description'] ?? '').toString();
    final category = (item['category'] ?? '').toString();

    final addr = (item['address'] ?? item['fridge_address'] ?? '').toString();
    final expiry = _dateText(item['expiry_date'] ?? item['expiryDate']);

    final lat =
        _numToDouble(item['lat']) ??
        _numToDouble(item['latitude']) ??
        _numToDouble(item['fridge_latitude']);
    final lng =
        _numToDouble(item['lng']) ??
        _numToDouble(item['longitude']) ??
        _numToDouble(item['fridge_longitude']);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SingleChildScrollView(
            child: DefaultTextStyle(
              style: TextStyle(color: _ink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (category.isNotEmpty) _infoLine("Kategori", category),
                  if (expiry.isNotEmpty) _infoLine("Son tüketim", expiry),
                  if (addr.isNotEmpty) _infoLine("Adres", addr),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      "Açıklama",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(desc),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.directions),
                          label: const Text("Yere Git"),
                          onPressed: (lat == null || lng == null)
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _openDirections(lat, lng);
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: Icon(
                            canRequest
                                ? Icons.send_outlined
                                : Icons.lock_outline,
                          ),
                          label: Text(
                            canRequest ? "İstek Gönder" : "Sadece Needy",
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: canRequest ? _brand : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: canRequest
                              ? () async {
                                  try {
                                    final itemId = (item['id'] as num).toInt();
                                    await DonationApiService().requestDonation(
                                      itemId: itemId,
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("İstek gönderildi"),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoLine(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: _ink),
          children: [
            TextSpan(
              text: "$k: ",
              style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
            ),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }

  void _onPickTap(LatLng pos) {
    if (!widget.pickerMode) return;
    setState(() => _pickedPos = pos);
  }

  void _confirmPick() {
    if (!widget.pickerMode) return;
    if (_pickedPos == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Haritadan bir nokta seç")));
      return;
    }
    Navigator.pop(context, _pickedPos);
  }

  Widget _topOverlayCard({required Widget child}) {
    if (_isDark) {
      return GlassBox(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return AppShell(
        withBackground: !widget.embedded,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return AppShell(
        withBackground: !widget.embedded,
        appBar: buildGlassAppBar(context: context, title: 'Harita'),
        body: Center(
          child: Text(
            error!,
            style: TextStyle(
              color: _isDark ? Colors.white : _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    final me = myPos!;
    final markers = widget.pickerMode
        ? <Marker>{
            if (_pickedPos != null)
              Marker(
                markerId: const MarkerId("picked"),
                position: _pickedPos!,
                infoWindow: const InfoWindow(title: "Seçilen konum"),
              ),
          }
        : Set<Marker>.of((_filteredMarkers ?? _allMarkers).values);

    // ✅ Arama çubuğunun kesin görünmesi için overlay top’u AppBar+statusbar altına alıyoruz.
    final topOffset = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return AppShell(
      withBackground: !widget.embedded,
      safeArea: false,
      appBar: widget.pickerMode
          ? AppBar(
              backgroundColor: _isDark ? Colors.transparent : _brand,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                "Konum Seç",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _confirmPick,
                  child: const Text(
                    "Seç",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            )
          : buildGlassAppBar(
              context: context,
              title: "Harita",
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMarkers,
                ),
              ],
            ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (c) => _mapCtrl = c,
              initialCameraPosition: CameraPosition(
                target: widget.pickerMode ? (widget.initialPick ?? me) : me,
                zoom: widget.pickerMode ? 15 : 13,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: markers,
              onTap: widget.pickerMode ? _onPickTap : null,
            ),
          ),

          if (!widget.pickerMode)
            Positioned(
              left: 12,
              right: 12,
              top: topOffset,
              child: Column(
                children: [
                  _topOverlayCard(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: _isDark ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ürün adı ara…",
                        hintStyle: TextStyle(
                          color: _isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : _ink.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: _isDark ? Colors.white : _ink,
                        ),
                        suffixIcon: _query.trim().isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: _isDark ? Colors.white : _ink,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged("");
                                },
                              ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _topOverlayCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Row(
                        children: [
                          Text(
                            "Yarıçap: ${radiusKm.toStringAsFixed(0)} km",
                            style: TextStyle(
                              color: _isDark ? Colors.white : _ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Slider(
                              value: radiusKm,
                              min: 1,
                              max: 50,
                              divisions: 49,
                              onChanged: (v) => setState(() => radiusKm = v),
                              onChangeEnd: (_) => _loadMarkers(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: widget.pickerMode
          ? GlassBar(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                _pickedPos == null
                    ? "Haritaya dokunarak konum seç. Sonra sağ üstten 'Seç'."
                    : "Seçilen: ${_pickedPos!.latitude.toStringAsFixed(5)}, ${_pickedPos!.longitude.toStringAsFixed(5)}",
                style: TextStyle(
                  color: _isDark ? Colors.white : _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
    );
  }
}

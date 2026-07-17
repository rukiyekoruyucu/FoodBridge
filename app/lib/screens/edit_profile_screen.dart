import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/services/user_service.dart';
import 'package:foodbridge/services/upload_service.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _userService = UserService();
  final UploadService _upload = createUploadService();
  final _picker = ImagePicker();

  late TextEditingController _fullNameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _avatarCtrl;

  bool _saving = false;
  bool _uploadingAvatar = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).user;
    _fullNameCtrl = TextEditingController(text: u?.fullName?.trim() ?? '');
    _usernameCtrl = TextEditingController(text: u?.username?.trim() ?? '');
    _bioCtrl = TextEditingController(text: u?.bio?.trim() ?? '');
    _avatarCtrl = TextEditingController(text: u?.avatarUrl?.trim() ?? '');
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Web'de fotoğraf yükleme kapalı. Android'de dene.")),
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

      setState(() => _uploadingAvatar = true);

      final url = await _upload.uploadImageFromPath(
        x.path,
        folder: 'avatars',
      );

      setState(() {
        _uploadingAvatar = false;
        _avatarCtrl.text = url;
      });
    } catch (e) {
      setState(() => _uploadingAvatar = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avatar yüklenemedi: $e')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _userService.updateMe(
        fullName: _fullNameCtrl.text.trim().isEmpty ? null : _fullNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
        avatarUrl: _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
      );

      await ref.read(authProvider.notifier).refreshMe();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellendi.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  InputDecoration _editDec(BuildContext ctx, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF7FDF9),
      labelStyle: TextStyle(
        color: _isDark ? Colors.white.withValues(alpha: 0.80) : _ink.withValues(alpha: 0.85),
        fontWeight: FontWeight.w800,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _brand, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar Section
            Container(
              decoration: BoxDecoration(
                color: _isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isDark ? Colors.white.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: _isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF6F7FB),
                      child: _uploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (_avatarCtrl.text.trim().isNotEmpty)
                              ? Image.network(
                                  _avatarCtrl.text.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person_outline,
                                    color: _isDark ? Colors.white : _ink,
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline,
                                  color: _isDark ? Colors.white : _ink,
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _avatarCtrl.text.trim().isEmpty
                          ? "Profil fotoğrafı ekle (opsiyonel)"
                          : "Fotoğraf seçildi",
                      style: TextStyle(
                        color: _isDark ? Colors.white : _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: (_saving || _uploadingAvatar) ? null : _pickAndUploadAvatar,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isDark ? Colors.white.withValues(alpha: 0.65) : _brand.withValues(alpha: 0.55),
                      ),
                      foregroundColor: _isDark ? Colors.white : _brand,
                    ),
                    child: const Text("Seç"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _fullNameCtrl,
              cursorColor: _brand,
              style: TextStyle(
                color: _isDark ? Colors.white : _ink,
                fontWeight: FontWeight.w800,
              ),
              decoration: _editDec(context, 'Ad Soyad'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameCtrl,
              cursorColor: _brand,
              style: TextStyle(
                color: _isDark ? Colors.white : _ink,
                fontWeight: FontWeight.w800,
              ),
              decoration: _editDec(context, 'Kullanıcı adı (benzersiz olmalı)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioCtrl,
              cursorColor: _brand,
              minLines: 3,
              maxLines: 5,
              style: TextStyle(
                color: _isDark ? Colors.white : _ink,
                fontWeight: FontWeight.w700,
              ),
              decoration: _editDec(context, 'Bio'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: _saving ? null : () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: _isDark ? Colors.white70 : _ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/utils/constants.dart';
import 'package:foodbridge/utils/auth_validators.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String _role = AppConstants.rolePersonal;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _usernameCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    final company = _companyCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    FocusScope.of(context).unfocus();

    String? err;

    err = AuthValidators.username(username);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    err = AuthValidators.fullName(fullName);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    err = AuthValidators.email(email);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    err = AuthValidators.password(pass);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    err = AuthValidators.confirmPassword(pass, confirmPass);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    if (_role == AppConstants.roleCorporate) {
      err = AuthValidators.companyName(company);
      if (err != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
        return;
      }

      err = AuthValidators.location(location);
      if (err != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            fullName: fullName,
            email: email,
            username: username,
            password: pass,
            role: _role,
            companyName: _role == AppConstants.roleCorporate ? company : null,
            location: _role == AppConstants.roleCorporate ? location : null,
          );

      if (mounted) Navigator.pop(context);
    } catch (_) {
      final errMsg = ref.read(authProvider).error ?? "Kayıt başarısız";
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(authProvider);

    return AppShell(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
            colors: [
              Color(0xFF9AF2CF), // açık mint
              Color(0xFF2ECC71), // canlı yeşil
              Color(0xFF0B6B3A), // koyu yeşil
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Theme(
              // ✅ sadece register kartını dark-glass gibi yap
              data: Theme.of(context).copyWith(brightness: Brightness.dark),
              child: GlassBox(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Hero logo (Login’den buraya premium akış)
                    Hero(
                      tag: 'appLogo',
                      child: Image.asset(
                        'assets/foodbridge_logo.png',
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      "Kayıt Ol",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _roleSelector(),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _nameCtrl,
                      decoration: _dec("Ad Soyad"),
                    ),
                    TextField(
                      controller: _usernameCtrl,
                      decoration: _dec("Kullanıcı Adı"),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dec("E-posta"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: _dec("Şifre").copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscure,
                      decoration: _dec("Şifre Tekrar"),
                    ),

                    if (_role == AppConstants.roleCorporate) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _companyCtrl,
                        decoration: _dec("Şirket Adı"),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationCtrl,
                        decoration: _dec("Konum"),
                      ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: st.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.90),
                          foregroundColor: const Color(0xFF0B6B3A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: st.isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Hesap Oluştur",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Zaten hesabın var mı? Giriş Yap",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _role,
          dropdownColor: const Color(0xFF1C6E5E),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(
              value: AppConstants.rolePersonal,
              child: Text("Bireysel"),
            ),
            DropdownMenuItem(
              value: AppConstants.roleCorporate,
              child: Text("Şirket"),
            ),
            DropdownMenuItem(
              value: AppConstants.roleNeedy,
              child: Text("İhtiyaç Sahibi"),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _role = v);
          },
        ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }
}

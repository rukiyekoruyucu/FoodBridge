import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/utils/auth_validators.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  late final AnimationController _logoCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _lift; // translateY (pixel)

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // daha “belirgin”
    );

    // Fade hızlı başlar, yumuşak biter
    _fade = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.05, 0.70, curve: Curves.easeOut),
    );

    // Scale: küçük -> biraz overshoot -> normal (pro)
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.55,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.18,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 30,
      ),
    ]).animate(_logoCtrl);

    // Lift: yukarıdan gelsin ama “zıplamasın”
    _lift = Tween<double>(
      begin: -110,
      end: 0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    _logoCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final e1 = AuthValidators.email(email);
    final e2 = AuthValidators.password(pass);
    if (e1 != null || e2 != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e1 ?? e2!)));
      return;
    }

    final notifier = ref.read(authProvider.notifier);

    try {
      await notifier.login(email: email, password: pass);
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      final err = ref.read(authProvider).error ?? "Giriş başarısız";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
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
              Color(0xFF9AF2CF), // açık mint (canlı ama patlamaz)
              Color(0xFF2ECC71), // doygun yeşil
              Color(0xFF0B6B3A), // koyu derin yeşil
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Theme(
              // ✅ sadece login kartını dark-glass gibi yap (diğer kartlar etkilenmez)
              data: Theme.of(context).copyWith(brightness: Brightness.dark),
              child: GlassBox(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),

                    // ✅ PRO + BELİRGİN: Hero + fade + scale + lift
                    Hero(
                      tag: 'appLogo',
                      child: FadeTransition(
                        opacity: _fade,
                        child: AnimatedBuilder(
                          animation: _logoCtrl,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _lift.value),
                              child: Transform.scale(
                                scale: _scale.value,
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/foodbridge_logo.png',
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      "FoodBridge'e Hoş Geldin!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),

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
                                "Giriş Yap",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text(
                        "Hesabın yok mu? Kayıt Ol",
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

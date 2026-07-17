import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/providers/theme_mode_provider.dart';
import 'package:foodbridge/widgets/app_shell.dart';
import 'package:foodbridge/providers/notification_prefs_provider.dart';

import 'notifications_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final notifAsync = ref.watch(notificationsEnabledProvider);
    final notifEnabled = notifAsync.value ?? true;
    final notifLoading = notifAsync.isLoading;
    final notifSubtitle = notifAsync.hasError
        ? 'Bildirim ayarı okunamadı (varsayılan: açık)'
        : 'Aç / kapa ve listeyi görüntüle';

    final ink = AppShell.kInk;
    final brand = AppShell.kGreen;

    Widget card({required Widget child}) {
      if (isDark) return GlassBox(child: child);

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
        child: child,
      );
    }

    return AppShell(
      appBar: buildGlassAppBar(context: context, title: 'Ayarlar'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
        children: [
          card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _LeadingIcon(
                    icon: Icons.settings,
                    isDark: isDark,
                    ink: ink,
                    brand: brand,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uygulama tercihleri',
                          style: TextStyle(
                            color: isDark ? Colors.white : ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hesap • Gizlilik • Bildirimler',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : ink.withValues(alpha: 0.70),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          _SectionTitle('Hesap', isDark: isDark, ink: ink),
          const SizedBox(height: 8),
          _SettingTile(
            isDark: isDark,
            ink: ink,
            brand: brand,
            icon: Icons.person_outline,
            title: 'Profil',
            subtitle: 'Kişisel bilgilerini görüntüle',
            onTap: () {
              context.push('/home/profile');
            },
          ),
          const SizedBox(height: 10),
          _SettingTile(
            isDark: isDark,
            ink: ink,
            brand: brand,
            icon: Icons.lock_outline,
            title: 'Güvenlik',
            subtitle: 'Şifre ve oturum ayarları',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Güvenlik ayarları yakında.')),
              );
            },
          ),

          const SizedBox(height: 14),
          _SectionTitle('Uygulama', isDark: isDark, ink: ink),
          const SizedBox(height: 8),

          _SwitchTile(
            isDark: isDark,
            ink: ink,
            brand: brand,
            icon: Icons.notifications_none,
            title: 'Bildirimler',
            subtitle: notifSubtitle,
            value: notifEnabled,
            loading: notifLoading,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            onChanged: (v) async {
              try {
                await ref
                    .read(notificationsEnabledProvider.notifier)
                    .setEnabled(v);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bildirim tercihi kaydedilemedi.'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          _SwitchTile(
            isDark: isDark,
            ink: ink,
            brand: brand,
            icon: Icons.dark_mode_outlined,
            title: 'Koyu mod',
            subtitle: 'Aç / kapa',
            value: isDark,
            onChanged: (v) {
              ref.read(themeModeProvider.notifier).state = v
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),

          const SizedBox(height: 14),
          _SectionTitle('Oturum', isDark: isDark, ink: ink),
          const SizedBox(height: 8),
          card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: _LeadingIcon(
                icon: Icons.logout,
                isDark: isDark,
                ink: ink,
                brand: brand,
              ),
              title: Text(
                'Çıkış yap',
                style: TextStyle(
                  color: isDark ? Colors.white : ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                'Hesabından güvenli şekilde çık',
                style: TextStyle(
                  color: isDark ? Colors.white70 : ink.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white70 : ink.withValues(alpha: 0.55),
              ),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color ink;

  const _SectionTitle(this.text, {required this.isDark, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white70 : ink.withValues(alpha: 0.70),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color ink;
  final Color brand;

  const _LeadingIcon({
    required this.icon,
    required this.isDark,
    required this.ink,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : brand.withValues(alpha: 0.12);

    final fg = isDark ? Colors.white : ink;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.transparent
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Icon(icon, color: fg),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final bool isDark;
  final Color ink;
  final Color brand;

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.isDark,
    required this.ink,
    required this.brand,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark
        ? GlassBox(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: _LeadingIcon(
                icon: icon,
                isDark: isDark,
                ink: ink,
                brand: brand,
              ),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
              onTap: onTap,
            ),
          )
        : Container(
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: _LeadingIcon(
                icon: icon,
                isDark: isDark,
                ink: ink,
                brand: brand,
              ),
              title: Text(
                title,
                style: TextStyle(color: ink, fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                  color: ink.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: ink.withValues(alpha: 0.55),
              ),
              onTap: onTap,
            ),
          );

    return card;
  }
}

class _SwitchTile extends StatelessWidget {
  final bool isDark;
  final Color ink;
  final Color brand;

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool loading;
  final VoidCallback? onTap;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.isDark,
    required this.ink,
    required this.brand,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.loading = false,
    this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = loading ? null : (onTap ?? () => onChanged(!value));

    final content = InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: effectiveOnTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            _LeadingIcon(icon: icon, isDark: isDark, ink: ink, brand: brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : ink.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch.adaptive(
                value: value,
                onChanged: (v) => onChanged(v),
                activeTrackColor: brand,
              ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white70 : ink.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );

    if (isDark) return GlassBox(child: content);

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
      child: content,
    );
  }
}

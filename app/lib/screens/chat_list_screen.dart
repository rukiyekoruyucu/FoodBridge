import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:foodbridge/providers/chat_threads_notifier.dart';
import 'package:foodbridge/widgets/app_shell.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchCtrl = TextEditingController();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => AppShell.kInk;
  Color get _brand => AppShell.kGreen;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _card({required Widget child, VoidCallback? onTap}) {
    if (_isDark) {
      return GlassBox(child: child);
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
      child: child,
    );
  }

  Widget _searchBox() {
    if (_isDark) {
      return GlassBox(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: "Sohbetleri ara…",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            border: InputBorder.none,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        decoration: InputDecoration(
          hintText: "Sohbetleri ara…",
          hintStyle: TextStyle(
            color: _ink.withValues(alpha: 0.55),
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(Icons.search, color: _ink),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ✅ avatar: url boşsa veya fail olursa harf/ikon
  Widget _avatar({
    required String partnerName,
    required String avatarUrl,
    required bool isDark,
  }) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : _brand.withValues(alpha: 0.12);

    final fg = isDark ? Colors.white : _ink;

    Widget fallback() {
      final letter = partnerName.trim().isNotEmpty
          ? partnerName.trim()[0].toUpperCase()
          : "?";
      return Container(
        color: bg,
        child: Center(
          child: Text(
            letter,
            style: TextStyle(fontWeight: FontWeight.w900, color: fg),
          ),
        ),
      );
    }

    if (avatarUrl.trim().isEmpty) {
      return ClipOval(child: fallback());
    }

    return ClipOval(
      child: Image.network(
        avatarUrl.trim(),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(chatThreadsProvider);
    final notifier = ref.read(chatThreadsProvider.notifier);

    final q = _searchCtrl.text.trim().toLowerCase();
    final threads = st.threads;

    final filtered = q.isEmpty
        ? threads
        : threads.where((t) {
            final name = (t.otherUserFullName ?? "").toLowerCase();
            final last = (t.lastMessage ?? "").toLowerCase();
            return name.contains(q) || last.contains(q);
          }).toList();

    return AppShell(
      appBar: buildGlassAppBar(
        context: context,
        title: 'Mesajlar',
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: st.isLoading ? null : () => notifier.refresh(),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: _searchBox(),
          ),
          Expanded(
            child: Builder(
              builder: (_) {
                if (st.isLoading) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => Shimmer.fromColors(
                      baseColor: _isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200,
                      highlightColor: _isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.grey.shade100,
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  );
                }
                if (st.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            st.error!,
                            style: TextStyle(
                              color: _isDark ? Colors.white : _ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            q.isEmpty ? "Henüz mesaj yok" : "Sonuç bulunamadı",
                            style: TextStyle(
                              color: _isDark ? Colors.white : _ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => notifier.refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = filtered[i];

                      final lastMessage = (t.lastMessage ?? "").trim();

                      final partnerId = t.otherUserId; // ✅ zaten var
                      final partnerName =
                          (t.otherUserFullName ?? '').trim().isNotEmpty
                          ? t.otherUserFullName!.trim()
                          : (partnerId != null
                                ? "Kullanıcı #$partnerId"
                                : "Kullanıcı");

                      final avatarUrl = (t.otherAvatarUrl ?? '').trim();

                      final titleColor = _isDark ? Colors.white : _ink;
                      final subColor = _isDark
                          ? Colors.white.withValues(alpha: 0.80)
                          : _ink.withValues(alpha: 0.75);

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          context.push('/chat/${t.id}', extra: {
                            'partnerName': partnerName,
                            'partnerId': partnerId,
                            'partnerAvatarUrl':
                                avatarUrl.isNotEmpty ? avatarUrl : null,
                          });
                        },
                        child: _card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: _avatar(
                                    partnerName: partnerName,
                                    avatarUrl: avatarUrl,
                                    isDark: _isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        partnerName,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: subColor,
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
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/providers/chat_notifier.dart';
import 'package:foodbridge/widgets/app_shell.dart';
import 'package:foodbridge/screens/public_profile_screen.dart';

class ChatScreen extends ConsumerWidget {
  final int roomId;
  final String partnerName;

  // ✅ profil açmak için gerekli
  final int? partnerId;
  final String? partnerAvatarUrl;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.partnerName,
    this.partnerId,
    this.partnerAvatarUrl,
  });

  String hhmm(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chatState = ref.watch(chatProvider(roomId));
    final authId = ref.watch(authProvider).user?.id;

    final brand = AppShell.kGreen;

    // ✅ canlı değil, “soft premium” gradient (light mode)
    const bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.0, 0.55, 1.0],
      colors: [Color(0xFFF4FFFA), Color(0xFFEAF7F0), Color(0xFFF7FFFB)],
    );

    void openPartnerProfile() {
      final pid = partnerId;
      if (pid == null || pid <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profil açılamadı: partnerId yok (chat açılırken gönderilmiyor).',
            ),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            userId: pid,
            displayName: partnerName,
            avatarUrl: partnerAvatarUrl,
          ),
        ),
      );
    }

    // ✅ avatar widget: url boşsa veya load fail olursa default icon
    Widget _partnerAvatar() {
      final av = (partnerAvatarUrl ?? '').trim();

      Widget fallback() => Container(
        color: Colors.white.withValues(alpha: 0.22),
        child: const Icon(Icons.person, color: Colors.white, size: 18),
      );

      if (av.isEmpty) {
        return ClipOval(child: fallback());
      }

      return ClipOval(
        child: Image.network(
          av,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return fallback();
          },
        ),
      );
    }

    return AppShell(
      withBackground: false,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.transparent : brand,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 12,
        title: InkWell(
          onTap: openPartnerProfile, // ✅ artık null değil
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              SizedBox(width: 36, height: 36, child: _partnerAvatar()),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  partnerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(
                  alpha: partnerId == null ? 0.35 : 1.0,
                ),
                size: 20,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(chatProvider(roomId).notifier).loadHistory();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? null : bgGradient,
          color: isDark ? const Color(0xFF060A12) : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                reverse: true,
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final message =
                      chatState.messages[chatState.messages.length - 1 - index];
                  final isMe = (authId != null) && (message.senderId == authId);

                  DateTime _parse(String s) {
                    try {
                      return DateTime.parse(s).toLocal();
                    } catch (_) {
                      return DateTime.now();
                    }
                  }

                  final created = _parse(message.createdAt);

                  return _MessageBubble(
                    isMe: isMe,
                    text: message.content,
                    timeText: hhmm(created),
                    isDark: isDark,
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _MessageInput(roomId: roomId, myUserId: authId),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String timeText;
  final bool isDark;

  const _MessageBubble({
    required this.isMe,
    required this.text,
    required this.timeText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = math.min(
      MediaQuery.of(context).size.width * 0.78,
      420.0,
    );

    final ink = AppShell.kInk;
    final brand = AppShell.kGreen;

    final textColor = isMe ? Colors.white : (isDark ? Colors.white : ink);
    final timeColor = isMe
        ? Colors.white.withValues(alpha: 0.65)
        : (isDark
              ? Colors.white.withValues(alpha: 0.65)
              : ink.withValues(alpha: 0.60));

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 10),
      bottomRight: Radius.circular(isMe ? 10 : 18),
    );

    final Decoration decoration;
    if (isMe) {
      decoration = BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brand.withValues(alpha: 0.95),
            const Color(0xFF12803A).withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.10),
          ),
        ],
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: borderRadius,
        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.08),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: DecoratedBox(
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 11,
                            color: timeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.done_all, size: 14, color: timeColor),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends ConsumerStatefulWidget {
  final int roomId;
  final int? myUserId;
  const _MessageInput({required this.roomId, required this.myUserId});

  @override
  ConsumerState<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<_MessageInput> {
  final controller = TextEditingController();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatProvider(widget.roomId).notifier)
        .sendMessage(text, myUserId: widget.myUserId);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ink = AppShell.kInk;
    final brand = AppShell.kGreen;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isDark
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    if (!_isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: _isDark ? Colors.white : ink,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Mesaj yaz...',
                    hintStyle: TextStyle(
                      color: (_isDark
                          ? Colors.grey
                          : ink.withValues(alpha: 0.55)),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: sendMessage,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: brand,
                  shape: BoxShape.circle,
                  boxShadow: _isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodbridge/services/chat_service.dart';
import 'package:foodbridge/models/chat_message.dart';
import 'package:riverpod/legacy.dart';
import 'chat_state.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final chatProvider = StateNotifierProvider.autoDispose.family<
  ChatNotifier, ChatState, String>((ref, donationId){

    final chatService = ref.watch(chatServiceProvider);

    ref.onDispose((){
      chatService.dispose();
    });

    return ChatNotifier(donationId, chatService);
  });

class ChatNotifier extends StateNotifier<ChatState>{
  final String _donationId;
  final ChatService _chatService;

  ChatNotifier(this._donationId, this._chatService) : super(ChatState()){
    _chatService.connectAndAuthenticate();
    _chatService.joinChatRoom(_donationId);

    _chatService.onNewMessage(_handleNewMessage);
  }

  void _handleNewMessage(Map<String, dynamic> data){
    final newMessage = ChatMessage.fromJson(data);

    state = state.copyWith(
      messages: [...state.messages, newMessage],
    );
  }

  void sendMessage(String content){
    _chatService.sendMessage(_donationId, content);
    // İyimser UI güncellemesi (mesajı gönderir göndermez listeye ekle)
    // NOTE: Bu optimistik yaklaşımdır. Backend'den onay gelmezse sorun olabilir.
    /*
    final tempMessage = ChatMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        donationId: _donationId,
        senderUserId: 'current_user_id', // Buraya AuthState'ten gerçek ID gelmeli
        content: content,
        sentAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(messages: [...state.messages, tempMessage]);
    */
  }
}
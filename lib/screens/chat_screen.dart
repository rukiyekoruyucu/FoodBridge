import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/providers/auth_notifier.dart';

import 'package:foodbridge/providers/chat_notifier.dart';


class ChatScreen extends ConsumerWidget{
  final String donationId;
  final String partnerName;

  const ChatScreen({super.key, required this.donationId, required this.partnerName});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final chatState = ref.watch(chatProvider(donationId));
    final authId = ref.watch(authProvider).user?.userId;

    return Scaffold(
      appBar: AppBar(title: Text('chat with $partnerName')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: chatState.messages.length,
              itemBuilder: (context, index){
                final message = chatState.messages[chatState.messages.length - 1 - index];
                final isMe = message.senderUserId == authId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Text(message.content),
                  ),
                );
              },
            ),),

            _MessageInput(donationId: donationId),
        ],
      ),
    );
  }
}

class _MessageInput extends ConsumerWidget{
  final String donationId;
  const _MessageInput({required this.donationId});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final controller = TextEditingController();

    void sendMessage(){
      if(controller.text.trim().isNotEmpty){
        ref.read(chatProvider(donationId).notifier).sendMessage(controller.text.trim());
        controller.clear();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20)
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: sendMessage,
          )
        ],
      ),
    );
  }
}
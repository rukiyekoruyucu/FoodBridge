import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  late io.Socket socket;

  final String chatServerUrl = 'http://localhost:3000'; // Replace with your chat server URL

  void connectAndAuthenticate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
  
    socket = io.io(chatServerUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
  });

  socket.connect();

  socket.onConnect((_) async {
    final idToken = await user.getIdToken();

    socket.emit('authenticate', {
      'token': idToken,
      'userId': user.uid,
  });
  });
  }
  void joinChatRoom(String donationId) {
    if(socket.connected) {
      socket.emit('joinRoom', donationId);
    }
  }

  void sendMessage(String donationId, String content) {
    if(socket.connected) {
      socket.emit('send-message', {
        'donationId': donationId,
        'content': content,
      });
    }
  }

  void onNewMessage(Function(Map<String, dynamic>) callback) {
    socket.on('new-message', (data) => callback(data));
  }

  void dispose() {
    socket.disconnect();
  }
}
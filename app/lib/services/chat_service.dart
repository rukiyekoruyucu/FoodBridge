import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:foodbridge/core/api_constants.dart';

class ChatService {
  late io.Socket socket;

  final String chatServerUrl = ApiConstants.socketBaseUrl;

  Future<void> connectAndAuthenticate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    socket = io.io(chatServerUrl, {
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
    });

    final completer = Completer<void>();

    socket.onConnect((_) {
      if (!completer.isCompleted) completer.complete();
    });

    socket.onConnectError((err) {
      if (!completer.isCompleted) completer.completeError(err);
    });

    socket.onError((err) {
      // debug için
    });

    socket.connect();
    await completer.future.timeout(const Duration(seconds: 6));

    final idToken = await user.getIdToken();
    socket.emit('authenticate', {'token': idToken});
  }

  void joinChatRoom(int roomId) {
    if (socket.connected) {
      socket.emit('joinRoom', roomId.toString());
    }
  }

  void sendSocketMessage(int roomId, String message) {
    if (socket.connected) {
      socket.emit('send-message', {
        'roomId': roomId.toString(),
        'message': message,
      });
    }
  }

  void onNewMessage(void Function(Map<String, dynamic>) cb) {
    socket.off('new-message');
    socket.on('new-message', (data) {
      cb(Map<String, dynamic>.from(data));
    });
  }

  void dispose() {
    if (socket.connected) socket.disconnect();
    socket.dispose();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  late IO.Socket socket;
  late StreamController<List<String>> _messagesController;

  @override
  void initState() {
    super.initState();

    _messagesController = StreamController<List<String>>.broadcast();

    socket = IO.io('wss://ws.postman-echo.com/socketio', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.on('connect', (_) {
      print('Connected to server');
    });

    socket.on('message', (data) {
      print('Received message: $data');
      _messages.add(data);
      _messagesController.add(_messages);
    });

    socket.on('disconnect', (_) {
      print('Disconnected from server');
    });

    socket.on('error', (error) {
      print('Error: $error');
    });

    socket.connect();
  }

  @override
  void dispose() {
    _messagesController.close();
    socket.disconnect();
    super.dispose();
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    print('Sending message: $message'); // Add this line
    _messages.add(message);
    _messagesController
        .add(_messages); // Notify the StreamBuilder of the updated messages
    if (message.isNotEmpty) {
      socket.emit('sendMessage', {'message': message});
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Add any additional actions here
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: _messagesController.stream,
              initialData: _messages,
              builder: (context, snapshot) {
                return ListView.builder(
                  shrinkWrap: true,
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            snapshot.data![index],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        fillColor: Color.fromARGB(255, 200, 217, 245),
                        filled: true,
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.mic))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

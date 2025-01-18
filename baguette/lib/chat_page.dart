import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String botLevel;

  ChatPage({required this.botLevel});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = []; // Store chat messages
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    String message = _controller.text;
    if (message.isEmpty) return;

    setState(() {
      messages.add({"user": message});
    });

    // Clear input field
    _controller.clear();

    // Call the appropriate bot endpoint based on the selected level
    final url = Uri.parse('http://192.168.43.244:5001/chat_${widget.botLevel}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': message}),  // Ensure this matches your Flask endpoint
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          messages.add({"bot": result['response'] ?? "Error fetching response"});
        });
      } else {
        setState(() {
          messages.add({"bot": "Error: ${response.statusCode}"});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"bot": "Error: $e"});
      });
    } finally {
      // Scroll to the bottom of the chat
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with Bot ${widget.botLevel}"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.containsKey("user")
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: message.containsKey("user")
                          ? Colors.blue[100]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message.values.first,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'chat_page.dart'; // This page will display chat UI with the selected bot

class BotsPage extends StatelessWidget {
  final List<String> botLevels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select a Bot"),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white, // Set the background color to white
        child: ListView.builder(
          itemCount: botLevels.length,
          itemBuilder: (context, index) {
            String botLevel = botLevels[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  title: Text(
                    "Chat Bot $botLevel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(botLevel: botLevel),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:baguette/key_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bots_page.dart';
import 'passages_page.dart';
import 'key_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  String _title = "Loading..";
  String _correctedContent = "";
  String _feedback = "";
  int _wordCount = 0;

  // This method is called when the app starts to generate the initial title
  @override
  void initState() {
    super.initState();
    _generateTitle(); // Generate the title on app start
  }

  // Method to generate title using the generate_title endpoint
  Future<void> _generateTitle() async {
    final url = Uri.parse('http://192.168.43.244:5001/generate_title');
    final randomNumber = Random().nextInt(10000);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': 'only one title without any other descriptions suitable for french essays and new title everytime do not repeat the same thing.' + ' #$randomNumber',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _title = result['title'] ?? "Error fetching title"; // Initialize title
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _refreshTitle() async {
    final url = Uri.parse('http://192.168.43.244:5001/refresh_title');
    final randomNumber = Random().nextInt(10000);
    try {

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'only one title without any other descriptions suitable for french essays' + ' #$randomNumber',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _title = result['another'] ?? "";

        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  // Method to submit text for correction
  Future<void> _submitText() async {
    final text = _textController.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter some text before submitting!")),
      );
      return;
    }

    final url = Uri.parse('http://192.168.43.244:5001/correct_content');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _wordCount += text.split(' ').length;
          _correctedContent = result['corrected_text'] ?? '';
        });
        await _getFeedback();
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Method to get feedback from the API
  Future<void> _getFeedback() async {
    final url = Uri.parse('http://192.168.43.244:5001/compare_match');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': _textController.text,
          'title': _title,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _feedback = result['feedback'] ?? '';
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Method to save text to Firestore
  Future<void> _saveTextToFirestore() async {
    final text = _textController.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nothing to save!")),
      );
      return;
    }

    final collection = FirebaseFirestore.instance.collection('passages');
    await collection.add({
      'title': _title,
      'original_text': text,
      'corrected_text': _correctedContent,
      'feedback': _feedback,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("It's saved to Firestore!")),
    );
  }

  // Method to refresh the text and title
  void _refreshText() async {
    setState(() {
      _textController.clear();
      _correctedContent = "";
      _feedback = "";
    });
    await _refreshTitle(); // Refresh the title when clearing text
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Baguette"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu'),
            ),
            ListTile(
              title: Text('Mots Écrits ($_wordCount)'),
              onTap: () {},
            ),
            ListTile(
              title: Text('Passages'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PassagesPage()),
                );
              },
            ),
            ListTile(
              title: Text('Keys'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KeyPage()),
                );
              },
            ),
            ListTile(
              title: Text('Chat with Bots'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BotsPage()),
                );
              },
            ),
            // other menu items...
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              TextField(
                controller: _textController,
                maxLines: 10,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Écrivez ici...',
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _submitText,
                    child: Text('Submit'),
                  ),
                  ElevatedButton(
                    onPressed: _saveTextToFirestore,
                    child: Text('Save'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_correctedContent.isNotEmpty)
                Text(
                  'Correction:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              if (_correctedContent.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    _correctedContent,
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                ),
              if (_feedback.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    'Feedback:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              if (_feedback.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    _feedback,
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshText,
        child: Icon(Icons.refresh),
      ),
    );
  }
}

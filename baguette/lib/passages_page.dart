import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PassagesPage extends StatefulWidget {
  @override
  _PassagesPageState createState() => _PassagesPageState();
}

class _PassagesPageState extends State<PassagesPage> {
  String searchQuery = '';
  double fontSize = 16.0; // Default font size

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Passages'),
        actions: [
          PopupMenuButton<double>(
            icon: Icon(Icons.text_fields),
            onSelected: (size) {
              setState(() {
                fontSize = size; // Change font size
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 14.0, child: Text('Font Size 14')),
              PopupMenuItem(value: 16.0, child: Text('Font Size 16')),
              PopupMenuItem(value: 18.0, child: Text('Font Size 18')),
              PopupMenuItem(value: 20.0, child: Text('Font Size 20')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query; // Update search query
                });
              },
            ),
            SizedBox(height: 8.0), // Spacing between search bar and list
            // Passages List
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('passages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No saved passages yet.'));
                  }

                  final passages = snapshot.data!.docs
                      .where((doc) => (doc['title'] as String)
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                      .toList();

                  return ListView.builder(
                    itemCount: passages.length,
                    itemBuilder: (context, index) {
                      final passage = passages[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.0), // Reduced vertical margin
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                passage['title'] ?? 'Untitled',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  // Delete the passage
                                  FirebaseFirestore.instance
                                      .collection('passages')
                                      .doc(passage.id)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PassageDetailPage(
                                  title: passage['title'] ?? 'Untitled',
                                  originalText: passage['original_text'] ?? '',
                                  correctedText: passage['corrected_text'] ?? '',
                                  feedback: passage['feedback'] ?? '',
                                  fontSize: fontSize,
                                  onDelete: () {
                                    // Delete the passage
                                    FirebaseFirestore.instance
                                        .collection('passages')
                                        .doc(passage.id)
                                        .delete();
                                    Navigator.pop(context); // Close the detail page after deletion
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PassageDetailPage extends StatelessWidget {
  final String title;
  final String originalText;
  final String correctedText;
  final String feedback;
  final double fontSize;
  final VoidCallback onDelete;

  PassageDetailPage({
    required this.title,
    required this.originalText,
    required this.correctedText,
    required this.feedback,
    required this.fontSize,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDelete, // Call delete function from parent
          ),
        ],
      ),
      body: PageView(
        children: [
          _buildDetailCard('User Wrote:', originalText),
          _buildDetailCard('Corrected Text:', correctedText),
          _buildDetailCard('Feedback:', feedback),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String text) {
    return SingleChildScrollView(
      child: Card(
        margin: EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
              SizedBox(height: 10),
              Text(
                text.isNotEmpty ? text : 'No content available.',
                style: TextStyle(fontSize: fontSize),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

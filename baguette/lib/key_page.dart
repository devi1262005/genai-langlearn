import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KeyPage extends StatefulWidget {
  @override
  _KeyPageState createState() => _KeyPageState();
}

class _KeyPageState extends State<KeyPage> {
  String _filteredContent = '';
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'doc', 'docx', 'srt', 'rtf'],
    );

    if (result != null) {
      setState(() {
        _isUploading = true;
      });

      final file = File(result.files.single.path!);
      await _uploadFile(file);
    }
  }

  Future<void> _uploadFile(File file) async {
    final url = Uri.parse('http://192.168.43.143:5001/generate_meaning');

    try {
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final result = jsonDecode(responseData);

        setState(() {
          _filteredContent = result['meaning']
              .replaceAll('\n', ' ')
              .trim(); // Remove newline characters from response
          _isUploading = false;
        });
      } else {
        print('Failed to upload file: ${response.statusCode}');
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Key Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Add Text File'),
            ),
            if (_isUploading) CircularProgressIndicator(),
            if (_filteredContent.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16.0),
                color: Colors.grey[200],
                child: Text(
                  _filteredContent,
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

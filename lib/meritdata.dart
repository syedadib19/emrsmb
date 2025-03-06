import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  List<dynamic> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final response = await http.get(Uri.parse('https://mrsmbetongsarawak.edu.my/emerit/api/fetch_students.php'));

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON
        setState(() {
          students = json.decode(response.body);
          isLoading = false;
        });
      } else {
        // If the server did not return a 200 OK response, throw an error
        throw Exception('Failed to load students');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students List'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? Center(child: Text('No students found'))
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return ListTile(
            title: Text(student['name']),
            subtitle: Text('College Number: ${student['college_number']} | Merit Points: ${student['merit_points']}'),
            leading: CircleAvatar(
              child: Text(student['id'].toString()),
            ),
          );
        },
      ),
    );
  }
}
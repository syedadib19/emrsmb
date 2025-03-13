import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentStatusPage extends StatefulWidget {
  @override
  _StudentStatusPageState createState() => _StudentStatusPageState();
}

class _StudentStatusPageState extends State<StudentStatusPage> {
  List students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentStatus();
  }

  Future<void> fetchStudentStatus() async {
    setState(() => isLoading = true);
    final url = Uri.parse("https://www.mrsmbetongsarawak.edu.my/skoq/contents/emerit/get_student_status.asp");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // Decode JSON

        if (data["status"] == "success" && data["students"] is List) {
          setState(() {
            students = data["students"]; // Extract the students list
            isLoading = false;
          });
        } else {
          showError("No student data available.");
        }
      } else {
        showError("Failed to load data.");
      }
    } catch (e) {
      showError("Error: ${e.toString()}");
    }
  }

  void showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Outing Status"), actions: [
        IconButton(icon: Icon(Icons.refresh), onPressed: fetchStudentStatus),
      ]),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? Center(child: Text("No student records found."))
          : ListView.separated(
        itemCount: students.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final student = students[index];
          final isOut = student["status"] == "OUT";

          return ListTile(
            leading: Icon(
              isOut ? Icons.exit_to_app : Icons.login,
              color: isOut ? Colors.red : Colors.green,
            ),
            title: Text(student["nama"], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NOMAK: ${student["nomak"]}"),
                Text("Last Update: ${student["last_update"]}"),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOut ? Colors.red[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                student["status"],
                style: TextStyle(
                  color: isOut ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

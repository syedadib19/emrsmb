import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentStatusPage extends StatefulWidget {
  @override
  _StudentStatusPageState createState() => _StudentStatusPageState();
}

class _StudentStatusPageState extends State<StudentStatusPage> {
  List students = [];
  List filteredStudents = [];
  bool isLoading = true;
  int countOut = 0;
  int countIn = 0;
  String filter = "ALL"; // Filter state: "ALL", "IN", "OUT"

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
          List studentList = data["students"];
          int outCount = studentList.where((s) => s["status"] == "OUT").length;
          int inCount = studentList.length - outCount;

          setState(() {
            students = studentList;
            countOut = outCount;
            countIn = inCount;
            filterStudents(); // Apply filter
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

  void filterStudents() {
    setState(() {
      if (filter == "IN") {
        filteredStudents = students.where((s) => s["status"] == "IN").toList();
      } else if (filter == "OUT") {
        filteredStudents = students.where((s) => s["status"] == "OUT").toList();
      } else {
        filteredStudents = List.from(students);
      }
    });
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
      appBar: AppBar(
        title: Text("Student Outing Status"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: fetchStudentStatus),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? Center(child: Text("No student records found."))
          : Column(
        children: [
          // Summary Section (Click to filter)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard("Inside", countIn, Colors.green, "IN"),
                _buildSummaryCard("Outside", countOut, Colors.red, "OUT"),
                _buildSummaryCard("All", students.length, Colors.blue, "ALL"),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final isOut = student["status"] == "OUT";

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(
                      isOut ? Icons.exit_to_app : Icons.login,
                      color: isOut ? Colors.red : Colors.green,
                    ),
                    title: Text(student["nama"],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("NOMAK: ${student["nomak"]}",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        Text("Last Update: ${student["last_update"]}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color, String statusFilter) {
    return GestureDetector(
      onTap: () {
        setState(() {
          filter = statusFilter;
          filterStudents(); // Apply the filter
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 100,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: filter == statusFilter ? color.withOpacity(0.5) : color.withOpacity(0.2),
          ),
          child: Column(
            children: [
              Text(
                "$count",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

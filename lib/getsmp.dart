import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SMPPage extends StatefulWidget {
  @override
  _SMPPageState createState() => _SMPPageState();
}

class _SMPPageState extends State<SMPPage> {
  List<Map<String, String>> students = [];
  bool isLoading = true; // Added to track loading state

  @override
  void initState() {
    super.initState();
    fetchSMPData();
  }

  Future<void> fetchSMPData() async {
    try {
      final response = await http.get(Uri.parse('https://www.mrsmbetongsarawak.edu.my/skoq/contents/emerit/get_smp.asp'));
      print("Server Response: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Ensure data is valid
        if (data.isEmpty) {
          print("No data received from server.");
          setState(() {
            students = [];
            isLoading = false;
          });
          return;
        }

        setState(() {
          students = data.map<Map<String, String>>((student) {
            return {
              'NAMA': student['NAMA'] ?? 'Unknown',
              'NOMAK': student['NOMAK'] ?? 'Unknown'
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load SMP data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching SMP data: $e');
      setState(() {
        students = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SMP Students')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? Center(child: Text("No students found."))
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(students[index]['NAMA']!),
            subtitle: Text('Nomak: ${students[index]['NOMAK']}'),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart'; //important fpr nfc
import 'dart:typed_data';

class NFCScreen extends StatefulWidget {
  @override
  _NFCScreenState createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen> {
  String? errorMessage;
  Map<String, dynamic>? studentData;

  Future<void> scanNFC() async {
    await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || ndef.cachedMessage == null) {
        setState(() => errorMessage = "Invalid NFC card.");
        return;
      }

      var records = ndef.cachedMessage!.records;
      if (records.isEmpty) {
        setState(() => errorMessage = "No data found on NFC card.");
        return;
      }

      Uint8List rawPayload = records.first.payload;
      if (rawPayload.isEmpty) {
        setState(() => errorMessage = "Empty NFC payload.");
        return;
      }

      // Extract the language code length
      int langCodeLength = rawPayload[0] & 0x3F; // First byte stores length

      // Decode the actual NOMAK value by skipping the language code
      String nomak = utf8.decode(rawPayload.sublist(langCodeLength + 1)).trim();

      setState(() => errorMessage = "NOMAK Read: $nomak"); // Debug Output

      await fetchStudentData(nomak);
    });
  }

  Future<void> fetchStudentData(String nomak) async {
    final url = Uri.parse("https://www.mrsmbetongsarawak.edu.my/skoq/contents/emerit/get_student.asp?nomak=$nomak");

    try {
      final response = await http.get(url);
      print("Response Body: ${response.body}"); // Debug print

      // Check if response contains unexpected HTML
      if (response.body.contains("<br>") || response.body.contains("Debug:")) {
        setState(() => errorMessage = "Server returned an invalid response.");
        return;
      }

      final data = jsonDecode(response.body); // Decode only if valid JSON
      if (data.isNotEmpty) {
        setState(() {
          studentData = data;
          errorMessage = null; // Clear error message if successful
        });
      } else {
        setState(() => errorMessage = "No student found for NOMAK: $nomak");
      }
    } catch (e) {
      setState(() => errorMessage = "Network error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NFC Student Lookup")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: scanNFC,
              child: Text("Scan NFC"),
            ),
            SizedBox(height: 20),
            if (errorMessage != null)
              Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16)),
            if (studentData != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    margin: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow("Name", studentData!['NAMA']),
                          _buildInfoRow("Class", studentData!['KLS']),
                          _buildInfoRow("Phone", studentData!['TELEFON']),
                          _buildInfoRow("Address", studentData!['ALAMAT']
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return SizedBox(); // Hide if empty

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }
}

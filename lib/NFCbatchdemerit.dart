import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NFCDemeritPage extends StatefulWidget {
  @override
  _NFCDemeritPageState createState() => _NFCDemeritPageState();
}

class _NFCDemeritPageState extends State<NFCDemeritPage> {
  List<String> scannedStudents = [];
  TextEditingController meritController = TextEditingController();
  int meritPoints = 0;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    startNFC();
  }

  void startNFC() async {
    if (!await NfcManager.instance.isAvailable()) {
      print('NFC not available');
      return;
    }

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null) return;

      try {
        NdefMessage message = await ndef.read();
        if (message.records.isNotEmpty) {
          String data = String.fromCharCodes(message.records.first.payload);
          String extractedCollegeNumber = data.substring(3);

          setState(() {
            if (!scannedStudents.contains(extractedCollegeNumber)) {
              scannedStudents.add(extractedCollegeNumber);
            }
          });

          print("Scanned: $extractedCollegeNumber");
        }
      } catch (e) {
        print("Error reading NFC: $e");
      }
    });
  }

  Future<void> grantDemeritBatch() async {
    if (scannedStudents.isEmpty || meritPoints <= 0) {
      print('No students scanned or invalid merit points');
      return;
    }

    setState(() => isProcessing = true);

    String apiUrl =
        'https://mrsmbetongsarawak.edu.my/emerit/api/grant_demerit_batch.php';

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'college_numbers': scannedStudents,
          'merit_points': meritPoints, // Positive value, backend converts it
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          setState(() => scannedStudents.clear());
          _showSuccessDialog();
        } else {
          print('Error: ${data['message']}');
        }
      } else {
        print('Failed to connect to server');
      }
    } catch (e) {
      print('Error: $e');
    }

    setState(() => isProcessing = false);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Success"),
        content: Text("Demerit applied to all scanned students."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NFC Demerit System')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: meritController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter demerit points per student',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  meritPoints = int.tryParse(value) ?? 0;
                });
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: scannedStudents.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: ListTile(
                      leading: Icon(Icons.remove_circle, color: Colors.red),
                      title: Text("College Number: ${scannedStudents[index]}",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isProcessing ? null : grantDemeritBatch,
              child: isProcessing
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Apply Demerit to All'),
            ),
          ],
        ),
      ),
    );
  }
}

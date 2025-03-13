import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class NfcOutingScreen extends StatefulWidget {
  @override
  _NfcOutingScreenState createState() => _NfcOutingScreenState();
}

class _NfcOutingScreenState extends State<NfcOutingScreen> {
  bool isLoading = false;
  String message = "Tap NFC card to scan";
  List<Map<String, String>> studentsOutside = [];

  @override
  void initState() {
    super.initState();
    fetchStudentsOutside();
  }

  Future<void> scanNfcAndUpdateStatus(String status) async {
    setState(() {
      isLoading = true;
      message = "Scanning NFC...";
    });

    await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        var ndef = Ndef.from(tag);
        if (ndef == null || ndef.cachedMessage == null) {
          showPopup("Scan Failed", "❌ Invalid NFC card.", Colors.red, false);
          return;
        }

        var records = ndef.cachedMessage!.records;
        if (records.isEmpty) {
          showPopup("Scan Failed", "❌ No data found on NFC card.", Colors.red, false);
          return;
        }

        Uint8List rawPayload = records.first.payload;
        if (rawPayload.isEmpty) {
          showPopup("Scan Failed", "❌ Empty NFC payload.", Colors.red, false);
          return;
        }

        int langCodeLength = rawPayload[0] & 0x3F;
        String nomak = utf8.decode(rawPayload.sublist(langCodeLength + 1)).trim();

        final url = Uri.parse("https://www.mrsmbetongsarawak.edu.my/skoq/contents/emerit/update_outing.asp");
        final response = await http.post(url, body: {
          "nomak": nomak,
          "keluar": status,
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["status"] == "success") {
            showPopup("✅ Success", data["message"] ?? "Outing status updated", Colors.green, true);
            fetchStudentsOutside();
          } else {
            showPopup("❌ Error", data["message"] ?? "Failed to update outing data", Colors.red, false);
          }
        } else {
          showPopup("❌ Error", "Server error. Try again later.", Colors.red, false);
        }
      } catch (e) {
        showPopup("❌ Error", "Exception: ${e.toString()}", Colors.red, false);
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future<void> fetchStudentsOutside() async {
    final url = Uri.parse("https://www.mrsmbetongsarawak.edu.my/skoq/contents/emerit/students_outside.asp");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        studentsOutside = data.map<Map<String, String>>((student) => {
          "nomak": student["nomak"].toString(),  // Ensure value is String
          "name": student["name"].toString(),    // Ensure value is String
        }).toList();
      });
    }
  }

  void showPopup(String title, String content, Color color, bool isSuccess) {
    if (isSuccess) {
      Vibration.vibrate(duration: 200);
    } else {
      Vibration.vibrate(duration: 500);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: color)),
          content: Text(content),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NFC Outing System")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : Column(
              children: [
                ElevatedButton(
                  onPressed: () => scanNfcAndUpdateStatus("OUT"),
                  child: Text("Scan to Exit"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => scanNfcAndUpdateStatus("IN"),
                  child: Text("Scan to Enter"),
                ),
              ],
            ),
            SizedBox(height: 30),
            Divider(),
            SizedBox(height: 10),
            Text("Students Currently Outside", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            studentsOutside.isEmpty
                ? Text("No students outside.")
                : Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: studentsOutside.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(studentsOutside[index]["name"]!),
                    subtitle: Text("NOMAK: ${studentsOutside[index]["nomak"]}"),
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

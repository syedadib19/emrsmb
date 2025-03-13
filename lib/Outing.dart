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
  bool isAutoScanEnabled = false;
  String autoScanMode = ""; // "IN" or "OUT"
  String message = "Tap NFC card to scan";
  String lastScannedNomak = "";
  String lastScannedNama = "";
  String lastScannedStatus = "";
  String lastScannedTime = "";

  @override
  void initState() {
    super.initState();
    loadLastScan();
  }
  void reloadPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => NfcOutingScreen()), // Replace with your main widget
    );
  }


  Future<void> saveLastScan(String nomak, String nama, String status) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String timestamp = DateTime.now().toString();

      await prefs.setString("lastNomak", nomak);
      await prefs.setString("lastNama", nama);
      await prefs.setString("lastStatus", status);
      await prefs.setString("lastTime", timestamp);

      if (!mounted) return; // Prevent calling setState if widget is disposed

      setState(() {
        lastScannedNomak = nomak;
        lastScannedNama = nama;
        lastScannedStatus = status;
        lastScannedTime = timestamp;
      });

    } catch (e) {
      print("Error saving last scan: $e");
    }
  }

  void showPopup(String title, String content, Color color, bool isSuccess) {
    if (!mounted) return;

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

  Future<void> loadLastScan() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        lastScannedNomak = prefs.getString("lastNomak") ?? "No scan history";
        lastScannedNama = prefs.getString("lastNama") ?? "-";
        lastScannedStatus = prefs.getString("lastStatus") ?? "-";
        lastScannedTime = prefs.getString("lastTime") ?? "-";
      });
    } catch (e) {
      print("Error loading last scan: $e");
    }
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
            String nama = data["nama"] ?? "Unknown";
            saveLastScan(nomak, nama, status);
            //showPopup("✅ Success", "${data["message"]}\nStudent: $nama", Colors.green, true); // i try to comment this to avoid popup every scan
          } else {
            showPopup("❌ Error", data["message"] ?? "Failed to update outing data", Colors.red, false);
          }
        } else {
          showPopup("❌ Error", "Server error. Try again later.", Colors.red, false);
        }
      } catch (e) {
        showPopup("❌ Error", "Exception: ${e.toString()}", Colors.red, false);
      } finally {
        if (isAutoScanEnabled && autoScanMode == status) {
          Future.delayed(Duration(milliseconds: 500), () {
            if (isAutoScanEnabled) {
              scanNfcAndUpdateStatus(status);
            }
          });
        } else {
          NfcManager.instance.stopSession();
        }
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void toggleAutoScan(String status) {
    setState(() {
      if (isAutoScanEnabled) {
        isAutoScanEnabled = false;
        autoScanMode = "";
        NfcManager.instance.stopSession();
      } else {
        isAutoScanEnabled = true;
        autoScanMode = status;
        scanNfcAndUpdateStatus(status);
      }
    });
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
            Text(
              "Last Scan: $lastScannedNomak - $lastScannedNama ($lastScannedStatus at $lastScannedTime)",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : Column(
              children: [
                ElevatedButton(
                  onPressed: () => toggleAutoScan("IN"),
                  child: Text(isAutoScanEnabled && autoScanMode == "IN"
                      ? "SUCCESS"
                      : "Start Auto Scan (IN)"),
                ),
                ElevatedButton(
                  onPressed: () => toggleAutoScan("OUT"),
                  child: Text(isAutoScanEnabled && autoScanMode == "OUT"
                      ? "SUCCESS"
                      : "Start Auto Scan (OUT)"),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  isAutoScanEnabled = false;
                  autoScanMode = "";
                  message = "Scanning Stopped"; // Update the UI message
                });

                try {
                  await NfcManager.instance.stopSession(); // Ensure it properly stops
                  reloadPage(context);
                } catch (e) {
                  print("Error stopping NFC session: $e");
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Stop Scanning", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

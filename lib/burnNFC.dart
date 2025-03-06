import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class BurnNFCPage extends StatefulWidget {
  @override
  _BurnNFCPageState createState() => _BurnNFCPageState();
}

class _BurnNFCPageState extends State<BurnNFCPage> {
  TextEditingController nomakController = TextEditingController();
  String status = "";

  Future<void> writeNFC() async {
    String nomak = nomakController.text.trim();
    if (nomak.isEmpty) {
      setState(() => status = "Please enter a NOMAK");
      return;
    }

    try {
      setState(() => status = "Scanning for NFC tag...");

      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        setState(() => status = "❌ NFC is not available on this device");
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            NdefMessage message = NdefMessage([
              NdefRecord.createText(nomak), // Writing NOMAK as a text record
            ]);

            Ndef? ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              setState(() => status = "❌ This NFC tag is not writable");
              return;
            }

            await ndef.write(message);
            setState(() => status = "✅ Successfully burned NOMAK: $nomak to NFC Card");

            // Stop the NFC session
            NfcManager.instance.stopSession();
          } catch (e) {
            setState(() => status = "❌ Error: ${e.toString()}");
            NfcManager.instance.stopSession(errorMessage: "Failed to write NFC");
          }
        },
      );
    } catch (e) {
      setState(() => status = "❌ Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Burn NFC Card")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nomakController,
              decoration: InputDecoration(
                labelText: "Enter NOMAK",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: writeNFC,
              child: Text("Burn to NFC Card"),
            ),
            SizedBox(height: 20),
            Text(status, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

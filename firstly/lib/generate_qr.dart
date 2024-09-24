import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // For JSON encoding/decoding
import 'dart:typed_data';  // For handling binary data
import 'dart:developer' as devtools show log;

class GenerateQRPage extends StatefulWidget {
  final String userID;  // Accept the userID as a parameter

  const GenerateQRPage({Key? key, required this.userID}) : super(key: key);

  @override
  State<GenerateQRPage> createState() => _GenerateQRPageState();
}

class _GenerateQRPageState extends State<GenerateQRPage> {
  bool isLoading = false;
  String? errorMessage;
  Uint8List? qrCodeImageBytes;

  @override
  void initState() {
    super.initState();
    _generateQRCode();  // Automatically generate the QR code when the page is loaded
  }

  // Function to generate QR code by sending a request to the backend
  Future<void> _generateQRCode() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse('http://10.0.2.2:3000/api/generateQRCode');  // Replace with actual backend URL
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userID': widget.userID,  // Send userID to backend
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final qrCodeImage = responseData['qrCodeImage'];  // Assuming QR code is in base64 format

        setState(() {
          qrCodeImageBytes = base64Decode(qrCodeImage);  // Decode the base64 string into bytes
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to generate QR Code. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      devtools.log('Error generating QR Code: $e');
      setState(() {
        errorMessage = 'An error occurred while generating the QR Code.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())  // Show a loading spinner while generating QR
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : qrCodeImageBytes != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.memory(qrCodeImageBytes!),  // Display the generated QR code image
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();  // Close the page
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text('Press the button to generate QR code.'),
                    ),
    );
  }
}

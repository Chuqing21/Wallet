import 'dart:convert';
import 'package:firstly/generateQRView.dart';
import 'package:firstly/services/auth/MSSQLAuthProvider.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'viewCV.dart'; // Make sure to import the viewCV page

class qrView extends StatefulWidget {
  const qrView({super.key});

  @override
  _qrViewState createState() => _qrViewState();
}

class _qrViewState extends State<qrView> {
  bool isLoading = true;
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();

  List<Map<String, dynamic>> qrCodes = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQRCodes(); // Fetch existing QR codes when the page loads
  }

  Future<void> _fetchQRCodes() async {
    await _authProvider.initialize();
    final user = _authProvider.currentUser;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      devtools.log("Check UserID");
      if (user != null) {
        devtools.log('Fetching QR Codes for UserID: ${user.accountID}');
        final qrCodeData =
            await _authProvider.fetchQRCodesByUserId(user.accountID);

        setState(() {
          qrCodes = qrCodeData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'User not logged in.';
          isLoading = false;
        });
      }
    } catch (e) {
      devtools.log('Error fetching QR Codes: $e');
      setState(() {
        errorMessage = 'Failed to load QR Codes. Please try again later.';
        isLoading = false;
      });
    }
  }

  // Function to delete a QR code
  Future<void> _deleteQRCode(int qrId) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _authProvider.deleteQRCode(qrId);
      await _fetchQRCodes(); // Refresh the list after deletion
    } catch (e) {
      devtools.log('Error deleting QR Code: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to fetch CV data and navigate to View CV page
  Future<void> _viewCV(int qrId) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch the CV data using qrId
      final cvData = await _authProvider.fetchCVDataByQRCode(qrId);
      devtools.log(cvData.toString());
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewCV(data: cvData), // Navigate to viewCV
        ),
      );
    } catch (e) {
      devtools.log('Error fetching CV data: $e');
      setState(() {
        errorMessage = 'Failed to load CV. Please try again later.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showQRCodeImage(String qrCodeImage, int qrId) {
    final qrCodeImageBytes = base64Decode(qrCodeImage);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enlarge QR image size to 2x its normal size
              Image.memory(
                qrCodeImageBytes,
                width: 250, // Adjust width to enlarge
                height: 250, // Adjust height to enlarge
                fit: BoxFit.contain, // Ensure the image fits the given space
              ),
              const SizedBox(height: 20),

              // Add "View CV" button here
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _viewCV(qrId); // Fetch CV data and show CV page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Set button color to blue
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'View CV',
                  style: TextStyle(
                    color: Colors.white, // White text color
                    fontWeight: FontWeight.bold, // Bold text
                    fontSize: 16, // Slightly larger text
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // "Delete QR Code" button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteQRCode(qrId); // Delete the QR code
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red background color
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Delete QR Code',
                  style: TextStyle(
                    color: Colors.white, // White text color
                    fontWeight: FontWeight.bold, // Bold text
                    fontSize: 16, // Optional: Increase font size slightly
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToGenerateQRView() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GenerateQRView()),
    );

    // Check if a QR code was generated and refresh the list if needed
    if (result == 'qr_generated') {
      _fetchQRCodes(); // Refresh the QR code list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Existing QR Codes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Body content (loading indicator, error message, or list of QR codes)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : qrCodes.isEmpty
                          ? const Center(child: Text('No QR Codes found.'))
                          : ListView.builder(
                              itemCount: qrCodes.length,
                              itemBuilder: (context, index) {
                                final qrCode = qrCodes[index];
                                final expireDate = DateTime.parse(qrCode['expireDate']);
                                final formattedDate = '${expireDate.day}/${expireDate.month}/${expireDate.year}';

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: ListTile(
                                    title: Text('QR Code ${index + 1}'),
                                    subtitle: Text('Expires on: $formattedDate'),
                                    onTap: () => _showQRCodeImage(
                                        qrCode['qrCodeImage'],
                                        qrCode['qrId']), // Ensure qrId is passed correctly
                                  ),
                                );
                              },
                            ),
            ),

            const SizedBox(height: 30), // Add some space before the button

            // Generate QR Code button at the bottom of the list
            Center(
              child: ElevatedButton(
                onPressed: _navigateToGenerateQRView,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Larger rounded button
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50, // More horizontal padding for larger button
                    vertical: 20, // More vertical padding for height
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20, // Larger font size for the button text
                  ),
                ),
                child: const Text('Generate QR Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

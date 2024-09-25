import 'package:flutter/material.dart';

class ReceiveCre extends StatelessWidget {
  const ReceiveCre({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        centerTitle: true,
        backgroundColor: const Color(0xFF171B63),
        title: const Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Certification',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // First Received Credential
              _buildReceivedCredentialField(context, 'images/receivedCre.png', 'Received Credentials'),
              const SizedBox(height: 20.0), // Space between the two containers
              // Duplicated Received Credential
              _buildReceivedCredentialField(context, 'images/receivedCre.png', 'Pending Credentials '),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedCredentialField(BuildContext context, String imagePath, String label) {
    return Container(
      width: 380.0,
      height: 90.0,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.transparent,
      ),
      child: InkWell(
        // Add any navigation or functionality as needed for onTap here
        child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(
                  imagePath,
                  width: 70.0, // Adjust width as needed
                  height: 70.0, // Adjust height as needed
                ),
              ),
              const SizedBox(
                  width: 20.0), // Space between image and text
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20.0,
                  color: Color(0xFF171B63),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

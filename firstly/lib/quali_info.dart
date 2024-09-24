import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'package:http/http.dart' as http;

class QualiInfoPage extends StatefulWidget {
  const QualiInfoPage({super.key});

  @override
  _QualiInfoPageState createState() => _QualiInfoPageState();
}

class _QualiInfoPageState extends State<QualiInfoPage> {
  final List<TextEditingController> _descriptionControllers = [
    TextEditingController(),
  ];
  final List<bool> _isPublicList = [true];
  String? _selectedCerType;
  List<Map<String, dynamic>> _availableCertifications = [];
  Map<String, dynamic>? _certificationDetails;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchCertifications();
    _fetchExistingQualifications(); // Fetch existing qualifications on init
  }

  @override
  void dispose() {
    for (var controller in _descriptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<int?> _getAccountID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('accountID');
    } catch (e) {
      print('Error retrieving accountID: $e');
      return null;
    }
  }

  Future<void> _fetchCertifications() async {
    final accountID = await _getAccountID();
    final url = 'http://10.0.2.2:3000/api/getCertificationTypes?accountID=$accountID';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _availableCertifications = (data['certifications'] as List)
              .map((cert) => {'CerID': cert['CerID'], 'CerType': cert['CerType']})
              .toList();
        });
      } else {
        devtools.log('Failed to load certifications: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error fetching certifications: $e');
    }
  }

  Future<void> _fetchExistingQualifications() async {
    final accountID = await _getAccountID();
    final url = 'http://10.0.2.2:3000/api/getCVQualiInfo?accountID=$accountID';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> qualifications = jsonDecode(response.body);
        setState(() {
          _descriptionControllers.clear();
          _isPublicList.clear();

          for (var qualification in qualifications) {
            _descriptionControllers.add(TextEditingController(text: qualification['description']));
            _isPublicList.add(qualification['isPublic']);
          }
        });
      } else {
        devtools.log('Failed to load qualifications: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error fetching qualifications: $e');
    }
  }

  Future<void> _saveQualifications() async {
    final accountID = await _getAccountID();
    final qualifications = _descriptionControllers.asMap().entries.map((entry) {
      int index = entry.key;
      return {
        'quaID': null, // Set ID to null for new entries
        'quaTitle': _selectedCerType,
        'quaIssuer': '', // Add issuer logic if applicable
        'quaDescription': entry.value.text,
        'quaAcquiredDate': DateTime.now().toIso8601String(), // Adjust as necessary
        'isPublic': _isPublicList[index]
      };
    }).toList();

    final url = 'http://10.0.2.2:3000/api/saveCVQuali';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accountID': accountID, 'qualifications': qualifications}),
      );

      if (response.statusCode == 200) {
        devtools.log('Qualifications saved successfully');
        _fetchExistingQualifications(); // Refresh qualifications
      } else {
        devtools.log('Failed to save qualifications: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error saving qualifications: $e');
    }
  }

  void _addQualificationEntry() {
    setState(() {
      _descriptionControllers.add(TextEditingController());
      _isPublicList.add(true);
    });
  }

  void _deleteQualificationEntry(int index) {
    setState(() {
      _descriptionControllers.removeAt(index);
      _isPublicList.removeAt(index);
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Widget _buildInputSection(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Qualification Information",
                  style: const TextStyle(
                    color: Color(0xFF171B63),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isEditing && index > 0) // Show delete button for added entries
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteQualificationEntry(index),
                  ),
              ],
            ),
          ),
          _buildDropdownField(context, 'Certification Type', _availableCertifications),
          const SizedBox(height: 15.0),
          if (_certificationDetails != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: ${_certificationDetails!['CerName'] ?? ''}"),
                Text("Email: ${_certificationDetails!['CerEmail'] ?? ''}"),
                Text("Issuer: ${_certificationDetails!['CerIssuer'] ?? ''}"),
                Text("Description: ${_certificationDetails!['CerDescription'] ?? ''}"),
                Text("Acquired Date: ${_certificationDetails!['CerAcquiredDate'] ?? ''}"),
              ],
            ),
          const SizedBox(height: 15.0),
          if (_isEditing)
            Row(
              children: [
                Checkbox(
                  value: _isPublicList[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _isPublicList[index] = value ?? true;
                    });
                  },
                ),
                const Text('Public'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context, String labelText,
      List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        DropdownButtonFormField<String>(
          value: _selectedCerType,
          hint: const Text('Select Certification'),
          onChanged: _isEditing
              ? (String? newValue) {
                  setState(() {
                    _selectedCerType = newValue;
                  });
                  final cerID = items.firstWhere(
                      (cert) => cert['CerType'] == newValue)['CerID'];
                  _fetchCertificationDetails(cerID.toString());
                }
              : null,
          items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> value) {
            return DropdownMenuItem<String>(
              value: value['CerType'],
              child: Text(
                value['CerType'],
                style: const TextStyle(fontSize: 14.0),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          ),
        ),
      ],
    );
  }

  Future<void> _fetchCertificationDetails(String cerID) async {
    final url = 'http://10.0.2.2:3000/api/getCertificationDetails?cerID=$cerID';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _certificationDetails = data;
        });
      } else {
        devtools.log('Failed to load certification details: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error fetching certification details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Qualification Information",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: ListView.builder(
          itemCount: _descriptionControllers.length,
          itemBuilder: (context, index) {
            return _buildInputSection(context, index);
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: _isEditing ? _saveQualifications : _toggleEditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF171B63),
                padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(color: Colors.white, fontSize: 15.0),
              ),
            ),
            if (_isEditing) // Show Add button only in edit mode
              ElevatedButton(
                onPressed: _addQualificationEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF171B63),
                  padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.white, fontSize: 15.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class AppWidget {
  static TextStyle headlineTextFieldStyle() {
    return const TextStyle(
      color: Color(0xFF171B63),
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle semiBoldTextFieldStyle() {
    return const TextStyle(
      color: Color(0xFF171B63),
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
    );
  }
}

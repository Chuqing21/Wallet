import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as devtools show log;
import 'package:path_provider/path_provider.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  _ProfileInfoPageState createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  XFile? _imageFile;
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  bool _isEditing = false; // Track whether the user is editing
  Map<String, String?> _errorMessages = {}; // Store error messages

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchProfileData(); // Fetch profile data when the page is initialized
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  Future<int?> _getAccountID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('accountID');
    } catch (e) {
      devtools.log('Error retrieving accountID: $e');
      return null;
    }
  }

  Future<void> _fetchProfileData() async {
  final accountID = await _getAccountID();
  if (accountID == null) {
    devtools.log('No accountID found');
    return;
  }

  devtools.log('Fetching profile for accountID: $accountID');

  try {
    // First try to fetch the CV profile
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/getCVProfile?accountID=$accountID'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        setState(() {
          _nameController.text = data[0]['name'] ?? '';
          _ageController.text = data[0]['age']?.toString() ?? '';
          _emailController.text = data[0]['email'] ?? '';
          _phoneController.text = data[0]['phone'] ?? '';
          _addressController.text = data[0]['address'] ?? '';
          _descriptionController.text = data[0]['description'] ?? '';
        });

        // Load profile image if available
        if (data[0]['profile_image_path'] != null &&
            data[0]['profile_image_path'].isNotEmpty) {
          try {
            final bytes = base64Decode(data[0]['profile_image_path']);
            final tempFile = File(
                '${(await getTemporaryDirectory()).path}/profile_image.png');
            await tempFile.writeAsBytes(bytes);
            setState(() {
              _imageFile = XFile(tempFile.path);
            });
          } catch (e) {
            devtools.log('Error decoding image: $e');
          }
        }
      } else {
        // If no CV profile data, fetch from Person table
        await _fetchPersonDetails(accountID);
      }
    } else {
      devtools.log('Failed to load profile data: ${response.statusCode}');
    }
  } catch (e) {
    devtools.log('Error fetching profile data: $e');
  }
}

Future<void> _fetchPersonDetails(int accountID) async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/getPersonDetails?accountID=$accountID'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null) {
        setState(() {
          _nameController.text = data['FullName'] ?? '';
          _emailController.text = data['Email'] ?? '';
          _phoneController.text = data['Mobile_Number'] ?? '';
          // You may want to leave age, address, and description empty or set defaults
        });
      } else {
        devtools.log('Person details not found');
      }
    } else {
      devtools.log('Failed to load person details: ${response.statusCode}');
    }
  } catch (e) {
    devtools.log('Error fetching person details: $e');
  }
}


  Future<void> _pickImage() async {
    if (_isEditing) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    setState(() {
                      if (pickedFile != null) {
                        _imageFile = pickedFile;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    setState(() {
                      if (pickedFile != null) {
                        _imageFile = pickedFile;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _saveCVProfile() async {
    final accountID = await _getAccountID() ?? 0;

    Uint8List? imageBytes;
    if (_imageFile != null) {
      imageBytes = await _imageFile!.readAsBytes();
    }

    final profileData = {
      'accountID': accountID,
      'photo': imageBytes != null ? base64Encode(imageBytes) : null,
      'name': _nameController.text.trim().toUpperCase(),
      'age': _ageController.text.trim().toUpperCase(),
      'email_address': _emailController.text.trim().toUpperCase(),
      'mobile_number': _phoneController.text.trim().toUpperCase(),
      'address': _addressController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim().toUpperCase(),
    };

    devtools.log('Saving profile data for accountID: $accountID');
    devtools.log('Profile data: $profileData');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/saveCVProfile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(profileData),
      );

      devtools.log('Response status: ${response.statusCode}');
      devtools.log('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        devtools.log('Profile saved successfully');
      } else {
        devtools.log('Failed to save profile: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error saving profile data: $e');
    }
  }

  void _validateFields() {
    setState(() {
      _errorMessages['name'] =
          _nameController.text.isEmpty ? 'Name cannot be empty.' : null;
      _errorMessages['age'] =
          _ageController.text.isEmpty ? 'Age cannot be empty.' : null;
      _errorMessages['email'] =
          _emailController.text.isEmpty ? 'Email cannot be empty.' : null;
      _errorMessages['phone'] =
          _phoneController.text.isEmpty ? 'Phone cannot be empty.' : null;
      _errorMessages['address'] =
          _addressController.text.isEmpty ? 'Address cannot be empty.' : null;
      _errorMessages['description'] = _descriptionController.text.isEmpty
          ? 'Description cannot be empty.'
          : null;
    });
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditing) {
        _validateFields();
        if (_errorMessages.values.every((error) => error == null)) {
          _saveCVProfile(); // Save data when toggling off edit mode
        } else {
          return; // Do not toggle edit mode if there are validation errors
        }
      }
      _isEditing = !_isEditing; // Toggle editing state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            Text('Profile Information', style: AppWidget.headlineTextFieldStyle()),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),
              InkWell(
                onTap: _isEditing ? _pickImage : null,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _imageFile == null
                        ? const Icon(Icons.camera_alt_outlined,
                            color: Colors.black)
                        : CircleAvatar(
                            radius: 80.0,
                            backgroundImage:
                                FileImage(File(_imageFile!.path)),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              _buildInputField("Name", _nameController, _errorMessages['name']),
              const SizedBox(height: 15.0),
              _buildInputField("Age", _ageController, _errorMessages['age']),
              const SizedBox(height: 15.0),
              _buildInputField("Email", _emailController, _errorMessages['email']),
              const SizedBox(height: 15.0),
              _buildInputField("Phone", _phoneController, _errorMessages['phone']),
              const SizedBox(height: 15.0),
              _buildInputField("Address", _addressController,
                  _errorMessages['address']),
              const SizedBox(height: 15.0),
              _buildInputField("Description", _descriptionController,
                  _errorMessages['description']),
              const SizedBox(height: 15.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: _toggleEditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF171B63),
                padding: const EdgeInsets.symmetric(
                    horizontal: 60.0, vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(color: Colors.white, fontSize: 15.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, String? errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        TextField(
          controller: controller,
          enabled: _isEditing,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12.0)),
          ),
      ],
    );
  }
}

class AppWidget {
  static TextStyle headlineTextFieldStyle() {
    return const TextStyle(
        color: Color(0xFF171B63), fontSize: 20.0, fontWeight: FontWeight.bold);
  }

  static TextStyle semiBoldTextFieldStyle() {
    return const TextStyle(
        color: Color(0xFF171B63), fontSize: 16.0, fontWeight: FontWeight.w600);
  }
}

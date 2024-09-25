// ignore_for_file: prefer_interpolation_to_compose_strings, non_constant_identifier_names

import 'package:firstly/qrView.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'package:firstly/services/auth/MSSQLAuthProvider.dart';
import 'package:http/http.dart' as http;

class GenerateQRView extends StatefulWidget {
  const GenerateQRView({Key? key}) : super(key: key);

  @override
  _GenerateQRViewState createState() => _GenerateQRViewState();
}

class _GenerateQRViewState extends State<GenerateQRView> {
  final _formKey = GlobalKey<FormState>();
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();

  bool isLoading = false;
  String? errorMessage;

  // Data from backend
  Map<String, dynamic> userProfile = {};
  List<dynamic> userEducation = [];
  List<dynamic> userWorkExperience = [];
  List<dynamic> userCertifications = [];
  List<dynamic> userSkills = []; // Add user skills

  // Selected IDs
  List<int> selectedEduBacIDs = [];
  List<int> selectedCerIDs = [];
  List<int> selectedSkillIDs = []; // Add selected skills

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user details on page load
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authProvider.initialize();
      final user = _authProvider.currentUser;

      if (user != null) {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/api/showDetails'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'accountID': user.accountID}),
        );

        if (response.statusCode == 200) {
          final details = jsonDecode(response.body);
          setState(() {
            userProfile = details['profile'];
            userEducation = details['education'];
            userWorkExperience = details['workExperience'];
            userCertifications = details['certification'];
            userSkills = details['skills']; // Assign skills data
          });

          // Log the userProfile to check if PerID is available
          devtools.log('User Profile: ${userProfile.toString()}');
          // Check if PerID exists
          if (userProfile.containsKey('perID')) {
            devtools.log('PerID: ${userProfile['perID']}');
          } else {
            devtools.log('PerID not found in userProfile');
          }
        } else {
          setState(() {
            errorMessage = 'Failed to fetch user details';
          });
        }
      } else {
        setState(() {
          errorMessage = 'User not logged in.';
        });
      }
    } catch (e) {
      devtools.log('Error fetching user details: $e');
      setState(() {
        errorMessage = 'Failed to fetch user details. Please try again later.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateQRCode() async {
    setState(() {
      isLoading = true;
    });

    final user = _authProvider.currentUser;
    if (user != null) {
      // Ensure that each ID string ends with a semicolon
      final EduBacID = selectedEduBacIDs.map((e) => '$e').join(';') + ';';
      final CerID = selectedCerIDs.map((e) => '$e').join(';') + ';';
      final SkillsID = selectedSkillIDs.map((e) => '$e').join(';') + ';';

      // Ensure PerID always ends with a semicolon
      final PerID =
          userProfile['perID'] != null ? '${userProfile['perID']};' : '';

      // Construct the QR data to be sent to the backend
      final qrData = {
        'userID': user.accountID.toString(),
        'EduBacID': EduBacID,
        'CerID': CerID,
        'SkillID': SkillsID,
        'PerID': PerID, // Ensure PerID ends with a semicolon
      };

      final response = await _authProvider.generateQRCode(
        userID: user.accountID.toString(),
        perID: PerID, // Send PerID with semicolon
        eduBacID: EduBacID,
        cerID: CerID,
        intelID: '',
        workExpID: '',
      );

      if (response != null) {
        devtools.log('QR Code Generated Successfully');
        _showGeneratedQRCode(response['qrCodeImage']);
      } else {
        setState(() {
          errorMessage = 'Failed to generate QR code. Please try again later.';
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // Function to display the generated QR code image
  void _showGeneratedQRCode(String qrCodeImage) {
    final qrCodeImageBytes = base64Decode(qrCodeImage);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generated QR Code'),
          content: Image.memory(qrCodeImageBytes),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(
                    context, 'qr_generated'); // Pop to qrView with result
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generate QR Code'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Profile Section
                            const Text('Profile:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            ListTile(
                              title: Text(userProfile['name'] ?? 'No Name'),
                              subtitle:
                                  Text(userProfile['email'] ?? 'No Email'),
                            ),
                            const SizedBox(height: 16),

                            // 2. Education Section
                            const Text('Education:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            ExpansionTile(
                              title: const Text('Select Education'),
                              children: userEducation.map((edu) {
                                return CheckboxListTile(
                                  value: selectedEduBacIDs
                                      .contains(edu['eduBacID']),
                                  title: Text(edu['institute_name'] ?? ''),
                                  subtitle: Text(edu['level'] ?? ''),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedEduBacIDs.add(edu['eduBacID']);
                                      } else {
                                        selectedEduBacIDs
                                            .remove(edu['eduBacID']);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // 3. Work Experience Section
                            const Text('Work Experience:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            ExpansionTile(
                              title: const Text('Select Work Experience'),
                              children: userWorkExperience.map((work) {
                                return CheckboxListTile(
                                  value: selectedEduBacIDs
                                      .contains(work['workExpID']),
                                  title: Text(work['job_title'] ?? ''),
                                  subtitle: Text(work['company_name'] ?? ''),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedEduBacIDs
                                            .add(work['workExpID']);
                                      } else {
                                        selectedEduBacIDs
                                            .remove(work['workExpID']);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // 4. Skills Section
                            const Text('Skills:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            ExpansionTile(
                              title: const Text('Select Skills'),
                              children: userSkills.map((skill) {
                                return CheckboxListTile(
                                  value: selectedSkillIDs
                                      .contains(skill['SoftID']),
                                  title: Text(skill['skill'] ?? ''),
                                  subtitle: Text(skill['description'] ?? ''),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedSkillIDs.add(skill['SoftID']);
                                      } else {
                                        selectedSkillIDs
                                            .remove(skill['SoftID']);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // 5. Certification Section
                            const Text('Certifications:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            ExpansionTile(
                              title: const Text('Select Certifications'),
                              children: userCertifications.map((cert) {
                                return CheckboxListTile(
                                  value: selectedCerIDs.contains(cert['cerID']),
                                  title: Text(cert['name'] ?? ''),
                                  subtitle: Text(cert['issuer'] ?? ''),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedCerIDs.add(cert['cerID']);
                                      } else {
                                        selectedCerIDs.remove(cert['cerID']);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // Generate QR Code Button
                            Center(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _generateQRCode,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 15,
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Generate QR Code'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

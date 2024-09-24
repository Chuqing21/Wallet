import 'package:firstly/show_error_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as devtools show log;

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

class SoftSkillInfoPage extends StatefulWidget {
  const SoftSkillInfoPage({super.key});

  @override
  _SoftSkillInfoPageState createState() => _SoftSkillInfoPageState();
}

class _SoftSkillInfoPageState extends State<SoftSkillInfoPage> {
  List<Map<String, dynamic>> _skillEntries = [];
  List<TextEditingController> _softSkillControllers = [];
  List<TextEditingController> _descriptionControllers = [];
  List<bool> _isPublicList = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeSkillEntries();
    _fetchSkillData();
  }

  void _initializeSkillEntries() {
    setState(() {
      _skillEntries.clear();
      _softSkillControllers.clear();
      _descriptionControllers.clear();
      _isPublicList.clear();
      _addSkillEntry(); // Only add one set of input fields initially
    });
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

  Future<void> _fetchSkillData() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/getCVSkill?accountID=$accountID'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _skillEntries.clear();
            _softSkillControllers.clear();
            _descriptionControllers.clear();
            _isPublicList.clear();

            if (data.isNotEmpty) {
              for (var entry in data) {
                _skillEntries.add(entry);
                _isPublicList.add(entry['isPublic'] ?? true);
                _softSkillControllers
                    .add(TextEditingController(text: entry['SoftHighlight']));
                _descriptionControllers.add(TextEditingController(
                    text: entry['SoftDescription'] ?? ''));
              }
            }
          });
        }
      } else {
        print(
            'Failed to fetch skill data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching skill data: $e');
    }
  }

  void _addSkillEntry() {
    setState(() {
      _skillEntries.add({
        'SoftID': null,
        'SoftHighlight': '',
        'SoftDescription': '',
        'isPublic': true,
      });
      _softSkillControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _isPublicList.add(true);
    });
  }

  Future<void> _saveSkills() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;

    List<Map<String, dynamic>> newSkillEntries = [];
    List<Map<String, dynamic>> existingSkillEntries = [];

    // Convert all existing skill names to uppercase for comparison
    List<String> existingSkillNames = _skillEntries
        .map((entry) => entry['SoftHighlight'].toString().toUpperCase())
        .toList();

    for (int i = 0; i < _skillEntries.length; i++) {
      if (_softSkillControllers[i].text.isEmpty ||
          _descriptionControllers[i].text.isEmpty) {
        continue; // Skip if fields are empty
      }

      // Convert the current skill name to uppercase for comparison
      String currentSkillName = _softSkillControllers[i].text.toUpperCase();
      String currentDescription = _descriptionControllers[i]
          .text
          .toUpperCase(); // Convert description to uppercase

      // Check if the current skill name already exists (excluding the current entry being edited)
      if (existingSkillNames.contains(currentSkillName) &&
          _skillEntries[i]['SoftID'] == null) {
        devtools.log("Duplicate skill found: $currentSkillName");
        showErrorDialog(context, 'Duplicate skill name: $currentSkillName');
        continue; // Skip saving this duplicate entry
      }

      final entry = {
        'SoftID': _skillEntries[i]['SoftID'],
        'SoftHighlight': currentSkillName,
        'SoftDescription': currentDescription, // Save description in uppercase
        'isPublic': _isPublicList[i],
      };

      if (_skillEntries[i]['SoftID'] == null) {
        newSkillEntries.add(entry);
        devtools.log("New Added");
      } else {
        existingSkillEntries.add(entry);
        devtools.log("Existing Added");
      }
    }

    final body = jsonEncode({
      'accountID': accountID,
      'newSkillEntries': newSkillEntries,
      'existingSkillEntries': existingSkillEntries,
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/saveCVSkill'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final response2 = await http.post(
        Uri.parse('http://10.0.2.2:3001/api/saino/saveCVSkill'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 && response2.statusCode == 200) {
        // Assume the backend returns the newly generated SoftID for newSkillEntries
        final responseData = jsonDecode(response.body);
        List updatedSkills = responseData['newSkillEntriesWithID'];

        // Update the _skillEntries with the generated SoftID
        for (int i = 0; i < newSkillEntries.length; i++) {
          _skillEntries[i]['SoftID'] = updatedSkills[i]['SoftID'];
        }

        devtools.log('Skill entries saved successfully.');
      } else {
        devtools.log(
            'Failed to save skill entries. Status code: ${response.statusCode}');
        showErrorDialog(context, 'Failed to save skill entries');
      }
    } catch (error) {
      devtools.log('Error saving skill entries: $error');
      showErrorDialog(context, 'Error saving skill entries');
    }
  }

  void _deleteSkillEntry(int index) async {
    final softID = _skillEntries[index]['SoftID'];
    final softHighlight = _skillEntries[index]['SoftHighlight'];
    if (softID != null) {
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/api/deleteCVSkill'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'SoftID': softID}),
        );
        final response2 = await http.post(
          Uri.parse('http://10.0.2.2:3001/api/saino/deleteCVSkill'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'InteHighlight': softHighlight}),
        );
        if (response.statusCode == 200 && response2.statusCode == 200) {
          setState(() {
            _skillEntries.removeAt(index);
            _softSkillControllers.removeAt(index);
            _descriptionControllers.removeAt(index);
            _isPublicList.removeAt(index);

            if (_skillEntries.isEmpty) {
              _addSkillEntry(); // Ensure at least one entry remains
            }
          });
        } else {
          showErrorDialog(context, 'Failed to delete skill entry');
        }
      } catch (e) {
        showErrorDialog(context, 'Error deleting skill entry: $e');
      }
    } else {
      // Handle case where SoftID is null
      setState(() {
        _skillEntries.removeAt(index);
        _softSkillControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
        _isPublicList.removeAt(index);

        if (_skillEntries.isEmpty) {
          _addSkillEntry(); // Ensure at least one entry remains
        }
      });
    }
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      await _saveSkills();
    }
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
                  "Skill Information ${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFF171B63),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSkillEntry(index),
                  ),
              ],
            ),
          ),
          // Skill name (editable only if it's a new skill, i.e., SoftID is null)
          _buildInputField(
              context,
              'Skill Name',
              _softSkillControllers[index],
              _skillEntries[index]['SoftID'] == null &&
                  _isEditing // Editable only for new entries
              ),
          const SizedBox(height: 15.0),

          // Description (always editable in edit mode)
          _buildInputField(context, 'Description',
              _descriptionControllers[index], _isEditing),
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

  Widget _buildInputField(BuildContext context, String labelText,
      TextEditingController controller, bool isEditing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        TextField(
          controller: controller,
          enabled: isEditing,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          ),
        ),
      ],
    );
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
        title: Text('Skill Information',
            style: AppWidget.headlineTextFieldStyle()),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _skillEntries.length,
                itemBuilder: (context, index) {
                  return _buildInputSection(context, index);
                },
              ),
              const SizedBox(height: 10.0),
              if (_isEditing)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _addSkillEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF171B63),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text('Add More Skills',
                        style: TextStyle(color: Colors.white, fontSize: 16.0)),
                  ),
                ),
              const SizedBox(height: 20.0),
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
}

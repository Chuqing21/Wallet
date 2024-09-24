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

class EducationInfoPage extends StatefulWidget {
  const EducationInfoPage({super.key});

  @override
  _EducationInfoPageState createState() => _EducationInfoPageState();
}

class _EducationInfoPageState extends State<EducationInfoPage> {
  final List<String> _educationLevels = [
    'HIGH SCHOOL',
    'FOUNDATION',
    'COLLAGE',
    'DIPLOMA',
    'BACHELOR’S DEGREE',
    'MASTER’S DEGREE',
    'PH.D.',
    'OTHER',
  ];

  List<Map<String, dynamic>> _educationEntries = [];
  List<String?> _selectedLevels = [];
  List<TextEditingController> _fieldOfStudyControllers = [];
  List<TextEditingController> _instituteNameControllers = [];
  List<TextEditingController> _instituteCountryControllers = [];
  List<TextEditingController> _instituteStateControllers = [];
  List<TextEditingController> _instituteCityControllers = [];
  List<String> _startDateList = [];
  List<String> _endDateList = [];
  List<bool> _isPublicList = [];
  bool _isEditing = false;

  // Validation error lists
  List<String> _levelErrors = [];
  List<String> _fieldOfStudyErrors = [];
  List<String> _instituteNameErrors = [];
  List<String> _instituteCountryErrors = [];
  List<String> _instituteStateErrors = [];
  List<String> _instituteCityErrors = [];
  List<String> _startDateErrors = [];
  List<String> _endDateErrors = [];

  @override
  void initState() {
    super.initState();
    _initializeEducationEntries();
    _fetchEducationData();
  }

  void _initializeEducationEntries() {
    setState(() {
      _educationEntries.clear();
      _selectedLevels.clear();
      _fieldOfStudyControllers.clear();
      _instituteNameControllers.clear();
      _instituteCountryControllers.clear();
      _instituteStateControllers.clear();
      _instituteCityControllers.clear();
      _startDateList.clear();
      _endDateList.clear();
      _isPublicList.clear();
      _addEducationEntry();
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

  Future<void> _fetchEducationData() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/api/getCVEducation?accountID=$accountID'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _educationEntries.clear();
            _selectedLevels.clear();
            _fieldOfStudyControllers.clear();
            _instituteNameControllers.clear();
            _instituteCountryControllers.clear();
            _instituteStateControllers.clear();
            _instituteCityControllers.clear();
            _startDateList.clear();
            _endDateList.clear();
            _isPublicList.clear();

            if (data.isNotEmpty) {
              for (var entry in data) {
                _educationEntries.add(entry);
                _isPublicList.add(entry['isPublic'] ?? true);
                _selectedLevels.add(entry['level']);
                _fieldOfStudyControllers
                    .add(TextEditingController(text: entry['field_of_study']));
                _instituteNameControllers
                    .add(TextEditingController(text: entry['institute_name']));
                _instituteCountryControllers.add(
                    TextEditingController(text: entry['institute_country']));
                _instituteStateControllers
                    .add(TextEditingController(text: entry['institute_state']));
                _instituteCityControllers
                    .add(TextEditingController(text: entry['institute_city']));
                _startDateList.add(entry['start_date'] ?? '');
                _endDateList.add(entry['end_date'] ?? '');
              }
            } else {
              _addEducationEntry();
            }
          });
        }
      } else {
        print(
            'Failed to fetch education data. Status code: ${response.statusCode}');
        if (mounted) {
          _addEducationEntry();
        }
      }
    } catch (e) {
      print('Error fetching education data: $e');
      if (mounted) {
        _addEducationEntry();
      }
    }
  }

  void _addEducationEntry() {
    setState(() {
      _educationEntries.add({
        'eduBacID': null,
        'level': null,
        'field_of_study': '',
        'institute_name': '',
        'institute_country': '',
        'institute_state': '',
        'institute_city': '',
        'start_date': '',
        'end_date': '',
        'isPublic': true,
      });
      _selectedLevels.add(null);
      _fieldOfStudyControllers.add(TextEditingController());
      _instituteNameControllers.add(TextEditingController());
      _instituteCountryControllers.add(TextEditingController());
      _instituteStateControllers.add(TextEditingController());
      _instituteCityControllers.add(TextEditingController());
      _startDateList.add('');
      _endDateList.add('');
      _isPublicList.add(true);
    });
  }

  Future<void> _saveEducationEntries() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;

    List<Map<String, dynamic>> newEducationEntries = [];
    List<Map<String, dynamic>> existingEducationEntries = [];
    List<int> newEntryIndexes = []; // Keep track of new entries' indexes

    // Convert existing entries to a set of unique combinations for validation
    Set<String> existingEntries = _educationEntries.map((entry) {
      return "${entry['level']?.toUpperCase()}_${entry['field_of_study']?.toUpperCase()}_${entry['institute_name']?.toUpperCase()}";
    }).toSet();

    for (int i = 0; i < _educationEntries.length; i++) {
      // Check for default or empty values and skip saving this entry if found
      if (_selectedLevels[i] == null ||
          _fieldOfStudyControllers[i].text.isEmpty ||
          _instituteNameControllers[i].text.isEmpty ||
          _instituteCountryControllers[i].text.isEmpty ||
          _instituteStateControllers[i].text.isEmpty ||
          _instituteCityControllers[i].text.isEmpty ||
          _startDateList[i].isEmpty ||
          _endDateList[i].isEmpty) {
        continue;
      }

      // Create a unique identifier for each entry to check for duplicates
      String entryKey = "${_selectedLevels[i]?.toUpperCase()}_${_fieldOfStudyControllers[i].text.toUpperCase()}_${_instituteNameControllers[i].text.toUpperCase()}";

      // Check if the combination of level, field of study, and institute name is already saved
      if (existingEntries.contains(entryKey) && _educationEntries[i]['eduBacID'] == null) {
        String selectedLevel = _selectedLevels[i]?.toUpperCase() ?? 'Unknown Level'; // Get the selected level
        String fieldOfStudy = _fieldOfStudyControllers[i].text.trim().toUpperCase(); // Get the field of study
  
        // Display the specific error message
        showErrorDialog(
          context,
          'Duplicate entry: $selectedLevel in $fieldOfStudy.'
        );
        continue; // Skip saving this duplicate entry
      }

      // Mark the entry as unique by adding it to the set
      existingEntries.add(entryKey);

      // Convert all input fields to uppercase before saving
      final entry = {
        'eduBacID': _educationEntries[i]['eduBacID'],
        'level': _selectedLevels[i]?.toUpperCase(),
        'field_of_study': _fieldOfStudyControllers[i].text.toUpperCase(),
        'institute_name': _instituteNameControllers[i].text.toUpperCase(),
        'institute_country': _instituteCountryControllers[i].text.toUpperCase(),
        'institute_state': _instituteStateControllers[i].text.toUpperCase(),
        'institute_city': _instituteCityControllers[i].text.toUpperCase(),
        'start_date': _startDateList[i],
        'end_date': _endDateList[i],
        'isPublic': _isPublicList[i],
      };

      if (_educationEntries[i]['eduBacID'] == null) {
        newEducationEntries.add(entry);
        newEntryIndexes.add(i); // Track the index of new entries in _educationEntries
      } else {
        existingEducationEntries.add(entry);
      }
    }

    final body = jsonEncode({
      'accountID': accountID,
      'newEducationEntries': newEducationEntries,
      'existingEducationEntries': existingEducationEntries,
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/saveCVEducation'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final response2 = await http.post(
        Uri.parse('http://10.0.2.2:3001/api/saino/saveCVEducation'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 && response2.statusCode == 200) {
        // Parse the response to get the new EduBacID entries
        final responseData = jsonDecode(response.body);
        List updatedEducations = responseData['newEducationEntriesWithID'];

        // Correctly update only the new entries in _educationEntries
        for (int i = 0; i < newEntryIndexes.length; i++) {
          int index = newEntryIndexes[i]; // Get the index of the new entry
          _educationEntries[index]['eduBacID'] =
              updatedEducations[i]['EduBacID']; // Update with correct EduBacID
          devtools.log("Added EduBacID to new entry at index: $index");
        }

        devtools.log('Education entries saved successfully.');
        setState(() {
          _isEditing = false;
        });
      } else {
        devtools.log(
            'Failed to save education entries. Status code: ${response.statusCode}');
        showErrorDialog(context, 'Failed to save education entries');
      }
    } catch (error) {
      devtools.log('Error saving education entries: $error');
      showErrorDialog(context, 'Error saving education entries');
    }
  }

  void _deleteEducationEntry(int index) async {
    final eduBacID = _educationEntries[index]['eduBacID'];
    final level = _educationEntries[index]['level'];
    final field_of_study = _educationEntries[index]['field_of_study'];
    final institute_name = _educationEntries[index]['institute_name'];
    if (eduBacID != null) {
      final confirmation = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete Confirmation"),
            content: const Text("Are you sure you want to delete this entry?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // Close the dialog and return false
                },
              ),
              TextButton(
                child: const Text("Delete"),
                onPressed: () {
                  Navigator.of(context)
                      .pop(true); // Close the dialog and return true
                },
              ),
            ],
          );
        },
      );

      if (confirmation == true) {
        try {
          final response = await http.post(
            Uri.parse('http://10.0.2.2:3000/api/deleteCVEducation'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'eduBacID': eduBacID}),
          );
          final response2 = await http.post(
            Uri.parse('http://10.0.2.2:3001/api/deleteCVEducation'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'level': level,
              'field_of_study': field_of_study,
              'institute_name': institute_name,
            }),
          );

          if (response.statusCode == 200 && response2.statusCode == 200) {
            setState(() {
              _educationEntries.removeAt(index);
              _selectedLevels.removeAt(index);
              _fieldOfStudyControllers.removeAt(index);
              _instituteNameControllers.removeAt(index);
              _instituteCountryControllers.removeAt(index);
              _instituteStateControllers.removeAt(index);
              _instituteCityControllers.removeAt(index);
              _startDateList.removeAt(index);
              _endDateList.removeAt(index);
              _isPublicList.removeAt(index);

              if (_educationEntries.isEmpty) {
                _addEducationEntry();
              }
            });
            devtools.log("Education entry deleted successfully");
          } else {
            showErrorDialog(context, 'Failed to delete education entry');
          }
        } catch (e) {
          devtools.log("Error deleting education entry: $e");
          showErrorDialog(context, 'Error deleting education entry');
        }
      }
    } else {
      setState(() {
        _educationEntries.removeAt(index);
        _selectedLevels.removeAt(index);
        _fieldOfStudyControllers.removeAt(index);
        _instituteNameControllers.removeAt(index);
        _instituteCountryControllers.removeAt(index);
        _instituteStateControllers.removeAt(index);
        _instituteCityControllers.removeAt(index);
        _startDateList.removeAt(index);
        _endDateList.removeAt(index);
        _isPublicList.removeAt(index);

        if (_educationEntries.isEmpty) {
          _addEducationEntry();
        }
      });
    }
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      await _saveEducationEntries(); // Save entries first
      setState(() {
        _isEditing = false; // Turn off editing mode after saving
      });
    } else {
      setState(() {
        _isEditing = true; // Turn on editing mode when "Edit" is clicked
      });
    }
  }

  Future<void> _selectMonthYear(BuildContext context, int index, bool isStart) async {
    DateTime? selectedDate = DateTime.now();
    if (isStart) {
      selectedDate = DateTime.tryParse(_startDateList[index]) ?? DateTime.now();
    } else {
      selectedDate = DateTime.tryParse(_endDateList[index]) ?? DateTime.now();
    }

    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        String formattedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
        if (isStart) {
          _startDateList[index] = formattedDate; // Save as year-month
        } else {
          _endDateList[index] = formattedDate; // Save as year-month
        }
      });
    }
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
                  "Education Information ${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFF171B63),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEducationEntry(index),
                  ),
              ],
            ),
          ),
          _buildDropdownField(
              context, 'Level of Education', _educationLevels, index),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'Field of Study',
              _fieldOfStudyControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'Institute Name',
              _instituteNameControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'Institute Country',
              _instituteCountryControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'Institute State',
              _instituteStateControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'Institute City',
              _instituteCityControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: _isEditing ? () => _selectMonthYear(context, index, true) : null, // Start Date
        child: AbsorbPointer(
          absorbing: !_isEditing, // Disable interaction when not editing
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              _startDateList[index], // Display the selected start date
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    ),
    const SizedBox(width: 15.0),
    Expanded(
      child: GestureDetector(
        onTap: _isEditing ? () => _selectMonthYear(context, index, false) : null, // End Date
        child: AbsorbPointer(
          absorbing: !_isEditing, // Disable interaction when not editing
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              _endDateList[index], // Display the selected end date
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    ),
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

  Widget _buildDropdownField(
      BuildContext context, String labelText, List<String> items, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        DropdownButtonFormField<String>(
          value: _selectedLevels[index],
          onChanged: _isEditing
              ? (String? newValue) {
                  setState(() {
                    _selectedLevels[index] = newValue;
                  });
                }
              : null,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
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
        title: Text('Education Information',
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
                itemCount: _educationEntries.length,
                itemBuilder: (context, index) {
                  return _buildInputSection(context, index);
                },
              ),
              const SizedBox(height: 10.0),
              if (_isEditing)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _addEducationEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF171B63),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text('Add More Education',
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

// Month-Year Picker Function
Future<DateTime?> showMonthYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      DateTime selectedDate = initialDate;

      return AlertDialog(
        title: const Text('Select Month and Year'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Month'),
              trailing: DropdownButton<int>(
                value: selectedDate.month,
                items: List.generate(12, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    selectedDate = DateTime(selectedDate.year, value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Year'),
              trailing: DropdownButton<int>(
                value: selectedDate.year,
                items: List.generate(lastDate.year - firstDate.year + 1, (index) {
                  return DropdownMenuItem(
                    value: firstDate.year + index,
                    child: Text(
                      "${firstDate.year + index}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    selectedDate = DateTime(value, selectedDate.month);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(selectedDate);
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

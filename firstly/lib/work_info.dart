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

class WorkInfoPage extends StatefulWidget {
  const WorkInfoPage({super.key});

  @override
  _WorkInfoPageState createState() => _WorkInfoPageState();
}

class _WorkInfoPageState extends State<WorkInfoPage> {
  bool _isEditing = false;
  List<Map<String, dynamic>> _workExperienceEntries = [];
  List<String?> _selectedIndustries = [];
  List<TextEditingController> _jobTitleControllers = [];
  List<TextEditingController> _companyNameControllers = [];
  List<TextEditingController> _countryControllers = [];
  List<TextEditingController> _stateControllers = [];
  List<TextEditingController> _cityControllers = [];
  List<TextEditingController> _descriptionControllers = [];
  List<TextEditingController> _startDateControllers = [];
  List<TextEditingController> _endDateControllers = [];
  List<TextEditingController> _otherIndustryControllers = [];
  List<bool> _isPublicControllers = [];

  final List<String> _industries = [
    'Accounting',
    'Finance',
    'Business',
    'Information Technology',
    'Data Science',
    'Marketing',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _initializeWorkEntries();
    _fetchWorkEntries();
  }

  void _initializeWorkEntries() {
    setState(() {
      _workExperienceEntries.clear();
      _selectedIndustries.clear();
      _jobTitleControllers.clear();
      _companyNameControllers.clear();
      _countryControllers.clear();
      _stateControllers.clear();
      _cityControllers.clear();
      _descriptionControllers.clear();
      _startDateControllers.clear();
      _endDateControllers.clear();
      _otherIndustryControllers.clear();
      _isPublicControllers.clear();
      _addWorkExperienceEntry();
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

  Future<void> _fetchWorkEntries() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/getCVWork?accountID=$accountID'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _workExperienceEntries =
              List<Map<String, dynamic>>.from(data.map((entry) {
            return {
              'workExpID': entry['workExpID'],
              'job_title': entry['job_title'],
              'company_name': entry['company_name'],
              'industry': entry['industry'],
              'country': entry['country'],
              'state': entry['state'],
              'city': entry['city'],
              'description': entry['description'],
              'start_date': entry['start_date'],
              'end_date': entry['end_date'],
              'isPublic': entry['isPublic'],
            };
          }));
          _initializeControllers();
        });
      } else {
        showErrorDialog(context, 'Failed to load work entries');
      }
    } catch (error) {
      devtools.log('No work entries: $error');
    }
  }

  void _initializeControllers() {
    _jobTitleControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['job_title']),
    );
    _companyNameControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['company_name']),
    );

    // Ensure the selected industries and other industry controllers are initialized correctly
    devtools.log('Initializing controllers...');
    devtools.log('Work Experience Entries: $_workExperienceEntries');

    // Initialize the selected industries and other industry controllers
    _selectedIndustries = [];
    _otherIndustryControllers = [];

    for (int index = 0; index < _workExperienceEntries.length; index++) {
      String industry =
          _workExperienceEntries[index]['industry']?.toUpperCase() ?? 'OTHERS';

      devtools.log('Processing industry for entry $index: $industry');

      if (_industries.map((i) => i.toUpperCase()).contains(industry)) {
        devtools.log(
            'Industry "$industry" found in the list, setting dropdown to it.');
        _selectedIndustries
            .add(industry); // Set the dropdown to the found industry
        _otherIndustryControllers
            .add(TextEditingController()); // No need for custom industry input
      } else {
        devtools.log(
            'Industry "$industry" not found, setting dropdown to "Others" and custom industry value.');
        _selectedIndustries.add('OTHERS'); // Set dropdown to 'Others'
        _otherIndustryControllers.add(TextEditingController(
            text: _workExperienceEntries[index]
                ['industry'])); // Set the custom industry value
      }
    }

    devtools.log('Selected Industries: $_selectedIndustries');
    devtools.log(
        'Custom Industry Controllers: ${_otherIndustryControllers.map((c) => c.text).toList()}');

    _countryControllers = List.generate(
      _workExperienceEntries.length,
      (index) =>
          TextEditingController(text: _workExperienceEntries[index]['country']),
    );
    _stateControllers = List.generate(
      _workExperienceEntries.length,
      (index) =>
          TextEditingController(text: _workExperienceEntries[index]['state']),
    );
    _cityControllers = List.generate(
      _workExperienceEntries.length,
      (index) =>
          TextEditingController(text: _workExperienceEntries[index]['city']),
    );
    _descriptionControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['description']),
    );
    _startDateControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['start_date']),
    );
    _endDateControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['end_date']),
    );
    _isPublicControllers = List.generate(
      _workExperienceEntries.length,
      (index) => _workExperienceEntries[index]['isPublic'] ?? true,
    );
  }

  Future<void> _saveWorkEntries() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;

    List<Map<String, dynamic>> newWorkEntries = [];
    List<Map<String, dynamic>> existingWorkEntries = [];
    List<int> newEntryIndexes = []; // Track indexes of new entries

    Set<String> uniqueEntries =
        {}; // To store unique job title and company name combinations

    for (int i = 0; i < _workExperienceEntries.length; i++) {
      // Skip entries with default/empty values
      if (_jobTitleControllers[i].text.isEmpty &&
          _companyNameControllers[i].text.isEmpty &&
          _selectedIndustries[i] ==
              'ACCOUNTING' && // Assuming 'ACCOUNTING' is the default
          _countryControllers[i].text.isEmpty &&
          _stateControllers[i].text.isEmpty &&
          _cityControllers[i].text.isEmpty &&
          _descriptionControllers[i].text.isEmpty &&
          _startDateControllers[i].text.isEmpty &&
          _endDateControllers[i].text.isEmpty) {
        continue;
      }

      // Convert job title and company name to uppercase for comparison
      String jobTitle = _jobTitleControllers[i].text.trim().toUpperCase();
      String companyName = _companyNameControllers[i].text.trim().toUpperCase();

      // Create a unique key by combining job title and company name
      String entryKey = '$jobTitle-$companyName';

      // Check if the combination already exists
      if (uniqueEntries.contains(entryKey)) {
        // Show error message if duplicate is found
        showErrorDialog(context,
            'Duplicate entry: Job Title "$jobTitle" at Company "$companyName" already exists.');
        return;
      }

      // Add the entry key to the set
      uniqueEntries.add(entryKey);

      // Create the work entry
      final entry = {
        'workExpID': _workExperienceEntries[i]['workExpID'],
        'job_title': jobTitle,
        'company_name': companyName,
        'industry': _selectedIndustries[i] == 'OTHERS'
            ? _otherIndustryControllers[i].text.toUpperCase()
            : _selectedIndustries[i]?.toUpperCase(),
        'country': _countryControllers[i].text.trim().toUpperCase(),
        'state': _stateControllers[i].text.trim().toUpperCase(),
        'city': _cityControllers[i].text.trim().toUpperCase(),
        'description': _descriptionControllers[i].text.trim().toUpperCase(),
        'start_date': _startDateControllers[i].text.trim().toUpperCase(),
        'end_date': _endDateControllers[i].text.trim().toUpperCase(),
        'isPublic': _isPublicControllers[i],
      };

      if (_workExperienceEntries[i]['workExpID'] == null) {
        newWorkEntries.add(entry);
        newEntryIndexes.add(i); // Track the index of the new entry
      } else {
        existingWorkEntries.add(entry);
      }
    }

    final body = jsonEncode({
      'accountID': accountID,
      'newWorkEntries': newWorkEntries,
      'existingWorkEntries': existingWorkEntries,
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/saveCVWork'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final response2 = await http.post(
        Uri.parse('http://10.0.2.2:3001/api/saino/saveCVWork'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 && response2.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List updatedWorkEntries = responseData['newWorkWithID'];

        // Correctly update new entries with their generated WorkExpID
        for (int i = 0; i < newEntryIndexes.length; i++) {
          int index = newEntryIndexes[i];
          _workExperienceEntries[index]['workExpID'] =
              updatedWorkEntries[i]['WorkExpID']; // Update the new WorkExpID
        }

        devtools.log('Work entries saved successfully.');
      } else {
        devtools.log(
            'Failed to save work entries. Status code: ${response.statusCode}');
        showErrorDialog(context, 'Failed to save work entries');
      }
    } catch (error) {
      devtools.log('Error saving work entries: $error');
      showErrorDialog(context, 'Error saving work entries');
    }
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      await _saveWorkEntries();
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _addWorkExperienceEntry() {
    setState(() {
      _workExperienceEntries.add({
        'workExpID': null,
        'job_title': '',
        'company_name': '',
        'industry': 'ACCOUNTING', // Set to default industry
        'country': '',
        'state': '',
        'city': '',
        'description': '',
        'start_date': '',
        'end_date': '',
        'isPublic': true,
      });
      _jobTitleControllers.add(TextEditingController());
      _companyNameControllers.add(TextEditingController());
      _selectedIndustries.add('ACCOUNTING'); // Set default industry
      _countryControllers.add(TextEditingController());
      _stateControllers.add(TextEditingController());
      _cityControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _startDateControllers.add(TextEditingController());
      _endDateControllers.add(TextEditingController());
      _otherIndustryControllers.add(TextEditingController());
      _isPublicControllers.add(true);
    });
  }

  Future<void> _deleteWorkExperienceEntry(int index) async {
    final workExpID = _workExperienceEntries[index]['workExpID'];
    final jobTitle = _workExperienceEntries[index]['job_title'];
    final companyName = _workExperienceEntries[index]['company_name'];
    if (workExpID != null) {
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/api/deleteCVWork'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'workExpID': workExpID}),
        );
        final body = jsonEncode({
          'job_title': jobTitle,
          'company_name': companyName,
        });
        final response2 = await http.post(
          Uri.parse('http://10.0.2.2:3001/api/saino/deleteCVWork'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        if (response.statusCode == 200 &&
            (response2.statusCode == 200 || response2.statusCode == 404)) {
          setState(() {
            _workExperienceEntries.removeAt(index);
            _jobTitleControllers.removeAt(index);
            _companyNameControllers.removeAt(index);
            _selectedIndustries.removeAt(index);
            _countryControllers.removeAt(index);
            _stateControllers.removeAt(index);
            _cityControllers.removeAt(index);
            _descriptionControllers.removeAt(index);
            _startDateControllers.removeAt(index);
            _endDateControllers.removeAt(index);
            _isPublicControllers.removeAt(index);

            if (_workExperienceEntries.isEmpty) {
              _addWorkExperienceEntry();
            }
          });
        } else {
          showErrorDialog(context, 'Failed to delete work entry');
        }
      } catch (e) {
        showErrorDialog(context, 'Error deleting work entry: $e');
      }
    } else {
      setState(() {
        _workExperienceEntries.removeAt(index);
        _jobTitleControllers.removeAt(index);
        _companyNameControllers.removeAt(index);
        _selectedIndustries.removeAt(index);
        _countryControllers.removeAt(index);
        _stateControllers.removeAt(index);
        _cityControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
        _startDateControllers.removeAt(index);
        _endDateControllers.removeAt(index);
        _isPublicControllers.removeAt(index);

        if (_workExperienceEntries.isEmpty) {
          _addWorkExperienceEntry();
        }
      });
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
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            Text('Work Experience', style: AppWidget.headlineTextFieldStyle()),
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
                itemCount: _workExperienceEntries.length,
                itemBuilder: (context, index) {
                  return _buildInputSection(context, index);
                },
              ),
              const SizedBox(height: 10.0),
              if (_isEditing)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _addWorkExperienceEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF171B63),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Add More Work Experience',
                      style: TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
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
                  "Work Experience ${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFF171B63),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteWorkExperienceEntry(index),
                  ),
              ],
            ),
          ),
          _buildInputField(
              context, 'Job Title', _jobTitleControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'Company Name',
              _companyNameControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildDropdownField(context, 'Industry', _industries, index,
              editable: _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(
              context, 'Country', _countryControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(
              context, 'State', _stateControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(
              context, 'City', _cityControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'Description',
              _descriptionControllers[index], _isEditing),
          const SizedBox(height: 15.0),
          Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use _buildInputField for Start Date
          _buildInputField(context, 'Start Date', _startDateControllers[index], _isEditing),
          const SizedBox(height: 15.0),
        ],
      ),
    ),
    const SizedBox(width: 15.0),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use _buildInputField for End Date
          _buildInputField(context, 'End Date', _endDateControllers[index], _isEditing),
          const SizedBox(height: 15.0),
        ],
      ),
    ),
  ],
),

          const SizedBox(height: 15.0),
          if (_isEditing)
            Row(
              children: [
                Checkbox(
                  value: _isPublicControllers[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _isPublicControllers[index] = value ?? true;
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

  Future<void> _selectMonthYear(
      BuildContext context, int index, bool isStart) async {
    // Parse the existing date or default to today
    DateTime selectedDate = isStart
        ? DateTime.tryParse(_startDateControllers[index].text) ?? DateTime.now()
        : DateTime.tryParse(_endDateControllers[index].text) ?? DateTime.now();

    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      String formattedDate =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startDateControllers[index].text =
              formattedDate; // Save as year-month
        } else {
          _endDateControllers[index].text = formattedDate; // Save as year-month
        }
      });
    }
  }

  Widget _buildDropdownField(
      BuildContext context, String labelText, List<String> items, int index,
      {required bool editable}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        DropdownButtonFormField<String>(
          value: _selectedIndustries[index], // Set initial value as 'OTHERS'
          onChanged: editable
              ? (String? newValue) {
                  setState(() {
                    _selectedIndustries[index] = newValue;
                    // Clear the text when anything other than 'Others' is selected
                    if (newValue != 'OTHERS') {
                      _otherIndustryControllers[index].clear();
                    }
                  });
                }
              : null,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value.toUpperCase(),
              child: Text(value.toUpperCase()),
            );
          }).toList(),
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          ),
        ),
        const SizedBox(height: 10.0),
        // Only show the text field if "Others" is selected
        if (_selectedIndustries[index] == 'OTHERS')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please specify the industry',
                  style: AppWidget.semiBoldTextFieldStyle()),
              const SizedBox(height: 10.0),
              TextField(
                controller: _otherIndustryControllers[
                    index], // Ensure this controller has the right text
                enabled: editable,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 15.0),
                  hintText: 'Enter Industry',
                ),
              ),
            ],
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
}

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
                items:
                    List.generate(lastDate.year - firstDate.year + 1, (index) {
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

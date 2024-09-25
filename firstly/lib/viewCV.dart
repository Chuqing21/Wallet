import 'package:flutter/material.dart';

class ViewCV extends StatelessWidget {
  final Map<String, dynamic> data;

  const ViewCV({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when the button is pressed
          },
        ),
        title: const Text('View CV'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.person, 'Profile Information'),
            _buildProfileSection(data['profile']),
            _buildSectionTitle(Icons.school, 'Education Information'),
            _buildEducationSection(data['education']),
            _buildSectionTitle(Icons.work, 'Work Experience'),
            _buildWorkSection(data['workExperience']),
            _buildSectionTitle(Icons.star, 'Qualifications'),
            _buildQualificationSection(data['qualification']),
            _buildSectionTitle(Icons.lightbulb, 'Soft Skills'),
            _buildSoftSkillsSection(data['softSkill']),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8.0),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic>? profile) {
    if (profile == null) return const SizedBox.shrink();
    return _buildInfoBox([
      'Name: ${profile['Name']}',
      'Age: ${profile['Age']}',
      'Email: ${profile['Email_Address']}',
      'Phone: ${profile['Mobile_Number']}',
      'Address: ${profile['Address']}',
      'Description: ${profile['Description']}',
    ]);
  }

  Widget _buildEducationSection(List<dynamic> education) {
    return Column(
      children: education.map((edu) {
        return _buildInfoBox([
          'Level: ${edu['LevelEdu']}',
          'Field of Study: ${edu['FieldOfStudy']}',
          'Institute Name: ${edu['InstituteName']}',
          'Country: ${edu['InstituteCountry']}',
          'City: ${edu['InstituteCity']}',
          'Start Date: ${edu['EduStartDate']}',
          'End Date: ${edu['EduEndDate']}',
        ]);
      }).toList(),
    );
  }

  Widget _buildWorkSection(List<dynamic> workExperience) {
    return Column(
      children: workExperience.map((work) {
        return _buildInfoBox([
          'Job Title: ${work['WorkTitle']}',
          'Company: ${work['WorkCompany']}',
          'Industry: ${work['WorkIndustry']}',
          'Country: ${work['WorkCountry']}',
          'City: ${work['WorkCity']}',
          'Description: ${work['WorkDescription']}',
          'Start Date: ${work['WorkStartDate']}',
          'End Date: ${work['WordEndDate']}',
        ]);
      }).toList(),
    );
  }

  Widget _buildQualificationSection(List<dynamic> qualification) {
    return Column(
      children: qualification.map((quali) {
        return _buildInfoBox([
          'Title: ${quali['CerTitle']}',
          'Issuer: ${quali['CerIssuer']}',
          'Description: ${quali['CerDescription']}',
          'Acquired Date: ${quali['CerAcquiredDate']}',
        ]);
      }).toList(),
    );
  }

  Widget _buildSoftSkillsSection(List<dynamic> softSkills) {
    return Column(
      children: softSkills.map((skill) {
        return _buildInfoBox([
          'Skill: ${skill['InteHighlight']}',
          'Description: ${skill['InteDescription']}',
        ]);
      }).toList(),
    );
  }

  Widget _buildInfoBox(List<String> info) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(20.0),
      width: double.infinity, // Make the box take up full width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: info.map((line) {
          return Text(
            line,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class CVStorage {
  final String apiUrl = "http://10.0.2.2:3000/api"; 

  Future<void> saveCVProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/saveCVProfile'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        print("Profile data saved successfully");
      } else {
        print("Failed to save profile data");
      }
    } catch (e) {
      print("Error occurred while saving profile data: $e");
    }
  }

  Future<void> saveCVEducation(Map<String, dynamic> educationData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/saveCVEducation'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(educationData),
      );

      if (response.statusCode == 200) {
        print("Education data saved successfully");
      } else {
        print("Failed to save education data");
      }
    } catch (e) {
      print("Error occurred while saving education data: $e");
    }
  }

  Future<void> saveCVWork(Map<String, dynamic> workData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/saveCVWork'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(workData),
      );

      if (response.statusCode == 200) {
        print("Work data saved successfully");
      } else {
        print("Failed to save work data");
      }
    } catch (e) {
      print("Error occurred while saving work data: $e");
    }
  }


Future<void> saveCVQuali(Map<String, dynamic> qualiData) async {
  try {
    print('Saving Qualification Data: ${json.encode(qualiData)}'); // Debugging print

    final response = await http.post(
      Uri.parse('$apiUrl/saveCVQuali'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(qualiData),
    );

    if (response.statusCode == 200) {
      print("Qualification data saved successfully");
    } else {
      print("Failed to save qualification data");
    }
  } catch (e) {
    print("Error occurred while saving qualification data: $e");
  }
}

Future<void> saveCVSoftSkill(Map<String, dynamic> softSkillData) async {
  try {
    print('Saving Soft Skill Data: ${json.encode(softSkillData)}'); // Debugging print

    final response = await http.post(
      Uri.parse('$apiUrl/saveCVSoftSkill'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(softSkillData),
    );

    if (response.statusCode == 200) {
      print("Soft Skill data saved successfully");
    } else if (response.statusCode == 400) {
      // Handle update logic here, if your endpoint supports updates
      final updateResponse = await http.put(
        Uri.parse('$apiUrl/updateSoftSkill'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(softSkillData),
      );
      if (updateResponse.statusCode == 200) {
        print("Soft Skill data updated successfully");
      } else {
        print("Failed to update soft skill data");
      }
    } else {
      print("Failed to save soft skill data");
    }
  } catch (e) {
    print("Error occurred while saving soft skill data: $e");
  }
}


  Future<void> updateHasCV(int accountID) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/updateHasCV'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"accountID": accountID}),
      );

      if (response.statusCode == 200) {
        print("hasCV updated successfully for accountID $accountID");
      } else {
        print("Failed to update hasCV for accountID $accountID");
      }
    } catch (e) {
      print("Error occurred while updating hasCV: $e");
    }
  }
}

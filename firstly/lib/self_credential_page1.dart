import 'package:firstly/education_info.dart';
import 'package:firstly/profile_info.dart';
import 'package:firstly/quali_info.dart';
import 'package:firstly/softskill_info.dart';
import 'package:firstly/work_info.dart';
import 'package:flutter/material.dart';
import 'credential2.dart';

class SelfCredentialPage1 extends StatelessWidget {
  const SelfCredentialPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // NO back button on top
        centerTitle: true,
        backgroundColor: const Color(0xFF171B63),
        title: const Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Wallet',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView( // Make the content scrollable
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildInfoBox(
                context,
                'images/profile.png', // Use the same image for all boxes
                'Profile',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return ProfileInfoPage(); // Navigate to ProfileInfoPage
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20.0), // Space between boxes
              _buildInfoBox(
                context,
                'images/education.png', // Use the same image for all boxes
                'Education',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return EducationInfoPage(); // Navigate to EducationPage
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20.0), // Space between boxes
              _buildInfoBox(
                context,
                'images/qualification.png', // Use the same image for all boxes
                'Certification',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return Credential2(); // Navigate to QualificationsPage
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20.0), // Space between boxes
              _buildInfoBox(
                context,
                'images/work.png', // Use the same image for all boxes
                'Work Experience',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return WorkInfoPage(); // Navigate to WorkExperiencePage
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20.0), // Space between boxes
              _buildInfoBox(
                context,
                'images/skill.png',
                'Soft Skill',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return SoftSkillInfoPage(); // Navigate to SoftSkillPage
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, String imagePath, String label, VoidCallback onTap) {
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
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(
                imagePath,
                width: 45.0, // Adjust width as needed
                height: 45.0, // Adjust height as needed
              ),
            ),
            const SizedBox(width: 20.0), // Space between image and text
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
    );
  }
}
